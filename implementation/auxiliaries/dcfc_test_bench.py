import threading
import time
import RPi.GPIO as GPIO
import atexit
import os
import sys
from types import SimpleNamespace

# user modules
from pid import Controller
from spmet import SPMeT
from can_wrapper import CAN
from can_definition_basytec import CanDefinition
from emulate_basytec import EmulatedBaSyTec
from thermistor_readout_and_averaging import Buffer
from configuration import *


# Paths of related files, controller parameters, time periods, CAN-IDs and Emulated Basytec can now be configured in configuration.py


class Scheduler:
    def __init__(self, interval, function, *args, **kwargs):
        # defining attributes containing state, period, lock and function
        self._timer = None
        self.interval = interval / 1000  # for input as ms
        self.function = function
        self.args = args
        self.kwargs = kwargs
        self.is_running = False
        self.start()
        # the lock is for making sure that a function is not running twice (if it needs longer then period)
        self.lock = threading.Lock()

    def _run(self):
        self.is_running = False
        self.start()  # start next timer
        # only run if last one is finished (else skip this one)
        if self.lock.acquire(blocking=False):
            self.function(*self.args, **self.kwargs)
            self.lock.release()

    def start(self):
        # start timer if not already started
        if not self.is_running:
            self._timer = threading.Timer(self.interval, self._run)
            self._timer.start()
            self.is_running = True

    def stop(self):
        self._timer.cancel()
        self.is_running = False


class TestBench:
    def __init__(self, emulated_basytec=0): # Emulated Basytec set to 0 for real-world testing
        # Cycle periods in ms
        # NOTE: absolute time will drift over time, do not use to small intervals
        self.acquire_temps_period = acquire_temps_period
        self.print_status_period = print_status_period
        self.control_fan_period = control_fan_period
        self.can_receive_period = can_receive_period
        self.can_send_temps_period = can_send_temps_period
        self.can_send_sim_period = can_send_sim_period
        self.update_sim_period = update_sim_period

        # Temperature moving average time in ms
        self.average_window_time = average_window_time
        self.moving_average_size = int(self.average_window_time / self.acquire_temps_period)

        # PWM Setup
        GPIO.setwarnings(False)  # block warning that channel is already in use
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(17, GPIO.OUT)
        self.fan_pwm = GPIO.PWM(17, 50)  # channel=12 frequency=50Hz
        self.fan_pwm.start(0)  # fan off
        self.fan_pwm_value = 0
        self.fan_rpm = 0

        # PID Setup
        self.pid_fan = Controller(FAN_PID_CONFIG)

        # Moving average Buffer Setup
        self.temp_buffer = Buffer(self.moving_average_size)

        # Emulate a virtual basytec to get feedback at testing if necessary
        self.use_emulated_basytec = emulated_basytec

        if self.use_emulated_basytec:
            self.emulated_basytec = EmulatedBaSyTec()
        else:
            # setup CAN
            # loading configfile from given path
            self.definition = CanDefinition(CONFIG_PATH)
            # creating can object with bitrate / extended id from config
            self.can = CAN(self.definition.bitrate, extended_id=self.definition.extended_id)

        # setup Battery Simulation
        path_to_simulink_elf = os.path.join(MATLAB_PATH_PREFIX, PATH_TO_ELF, NAME_OF_ELF) \
            .replace("\\", "/").replace(" ", "_").replace("/C:/", "/C/")  # Match Windows Path to Linux Path
        if not os.path.isfile(path_to_simulink_elf):
            sys.exit("Simulation file not found, please check path. Constructed path is: \n" + path_to_simulink_elf)

        self.simulation = SPMeT(path_elf=path_to_simulink_elf)
        self.current_from_sim = 0

        # initialize status variables
        self.sent_can_successful = False

        # initialize namespace for received variables
        self.recv = SimpleNamespace()

        # init receive from basytec (values)
        self.recv.soc = 0
        self.recv.current = 0
        self.recv.voltage = 0

        # init receive from basytec (init)
        self.recv.init_soc = 0
        self.recv.init_capacity = 0
        self.recv.init_sei_resistance = 0
        self.recv.init_temp_core = 0
        self.recv.init_ready = 0

        # init receive from basytec (control)
        self.recv.max_current = 0
        self.recv.max_voltage = 0
        self.recv.max_tempt_core = 0
        self.recv.min_pot_n = 0
        self.recv.start_sim = 0
        self.recv.set_temp_fan = 26  # initial target temp before can input. Should keep fan off

        # store last recv time, to check if recv works
        self.recv_last_timestamp = 0

        # setup and start schedulers
        self.scheduler_acquire_temps = Scheduler(self.acquire_temps_period, self.temp_buffer.read_temp)
        self.scheduler_print_status = Scheduler(self.print_status_period, self.print_status_new)
        self.scheduler_control_fan = Scheduler(self.control_fan_period, self.control_fan)
        self.scheduler_can_receive = Scheduler(self.can_receive_period, self.receive_can)
        self.scheduler_can_send_temps = Scheduler(self.can_send_temps_period, self.send_can_fan_and_temp_values)
        self.scheduler_control_sim = Scheduler(self.update_sim_period, self.update_sim)
        self.scheduler_can_send_sim = Scheduler(self.can_send_sim_period, self.send_can_sim_values)

    def receive_can(self):

        if self.use_emulated_basytec: # write values for basytec emulation
            data = self.emulated_basytec.receive_from_emulated_basytec()
            self.recv.last_timestamp = time.time()
            self.recv.soc = data["actual_soc"]
            self.recv.current = data["actual_current"]
            self.recv.voltage = data["actual_voltage"]

            self.recv.init_soc = data["init_soc"]
            self.recv.init_capacity = data["init_capacity"]
            self.recv.init_sei_resistance = data["init_sei_r"]
            self.recv.init_temp_core = data["init_temp_core"]

            self.recv.max_current = data["max_current"]
            self.recv.max_voltage = data["max_voltage"]
            self.recv.max_tempt_core = data["max_temp_core"]
            self.recv.min_pot_n = data["min_pot_n"]
            self.recv.start_sim = data["start_simulation"]
            self.recv.set_temp_fan = data["set_temp_fan"]
            self.recv.init_ready = True

        else: #
            can_input, can_id = self.can.receive()
            if can_input:
                # decode data
                data = self.definition.decode_data_from_basytec(can_id, can_input)
                self.recv_last_timestamp = time.time()
                # get received values from returned dicts
                if can_id == ID_Values_from_BaSyTec:
                    self.recv.soc = data["actual_soc"]
                    self.recv.current = data["actual_current"]
                    self.recv.voltage = data["actual_voltage"]

                elif can_id == ID_init_Values_from_BaSyTec:
                    self.recv.init_soc = data["init_soc"]
                    self.recv.init_capacity = data["init_capacity"]
                    self.recv.init_sei_resistance = data["init_sei_r"]
                    self.recv.init_temp_core = data["init_temp_core"]
                    self.recv.init_ready = True

                elif can_id == ID_Control_from_BaSyTec:
                    # if BaSyTec wants to start simulation, set init_ready False so init msg has to be received
                    if data["start_simulation"] and not self.recv.start_sim:
                        self.recv.init_ready = False
                    self.recv.max_current = data["max_current"]
                    self.recv.max_voltage = data["max_voltage"]
                    self.recv.max_tempt_core = data["max_temp_core"]
                    self.recv.min_pot_n = data["min_pot_n"]
                    self.recv.start_sim = data["start_simulation"]
                    self.recv.set_temp_fan = data["set_temp_fan"]

                else:
                    print("Received message from unknown CAN ID. ID was:", can_id)

            # setting all received variables to None if no more CAN Messages arrive
            if time.time() - self.recv_last_timestamp > 2:
                for var in self.recv.__dict__:
                    self.recv.__dict__[var] = None

        # only set SP here as the fan control frequency can be higher as the can
        if self.recv.set_temp_fan is None:
            self.pid_fan.set_point = 99
        else:
            self.pid_fan.set_point = self.recv.set_temp_fan

    def send_can_fan_and_temp_values(self):
        can_id = ID_Fan_Controller_to_BaSyTec
        values = {"fan_pwm": self.fan_pwm_value,
                  "fan_rpm": self.fan_rpm,
                  "controller_p": self.pid_fan.p_value,
                  "controller_i": self.pid_fan.i_value,
                  "controller_d": self.pid_fan.d_value,
                  }
        if self.use_emulated_basytec:
            self.sent_can_successful = self.emulated_basytec.send_to_emulated_basytec(values, can_id)
        else:
            # encode data packet and send it out via can
            data_out = self.definition.encode_data_for_basytec(can_id, values)
            self.sent_can_successful = self.can.send(can_id, data_out)

        self.send_can_temps()

    def send_can_temps(self):
        can_id = ID_Temps_to_BaSyTec
        temps = self.temp_buffer.get_averages()
        values = {"t_a": temps[0], "t_b": temps[1], "t_c": temps[2], "t_status": 1}

        if self.use_emulated_basytec:
            self.sent_can_successful = self.emulated_basytec.send_to_emulated_basytec(values, can_id)
        else:
            # encode data packet and send it out via can
            data_out = self.definition.encode_data_for_basytec(can_id, values)
            self.sent_can_successful = self.can.send(can_id, data_out)

    def send_can_sim_values(self):
        if self.simulation.sim_initialized:
            self.send_can_sim_values_general()
            self.send_can_sim_values_anode()
            self.send_can_sim_values_cathode()

    def send_can_sim_values_general(self):
        can_id = ID_Sim_to_BaSyTec
        values = {"voltage_sim": self.simulation.sim_out_dict["V"],
                  "soc_sim": self.simulation.sim_out_dict["soc"],
                  "temp_core_sim": self.simulation.sim_out_dict["temp_core"],
                  "t_solve": self.simulation.sim_out_dict["t_solve"],
                  "set_current_sim": self.current_from_sim,
                  }
        if self.use_emulated_basytec:
            self.sent_can_successful = self.emulated_basytec.send_to_emulated_basytec(values, can_id)
        else:
            # encode data packet and send it out via can
            data_out = self.definition.encode_data_for_basytec(can_id, values)
            self.sent_can_successful = self.can.send(can_id, data_out)

    def send_can_sim_values_anode(self):
        can_id = ID_Sim_to_BaSyTec_Anode  
        values = {"pot_n": self.simulation.sim_out_dict["pot_n"],
                  "eta_n": self.simulation.sim_out_dict["eta_n"],
                  "eta_sei_n": self.simulation.sim_out_dict["eta_sei_n"],
                  "delta_c_n_max": self.simulation.sim_out_dict["delta_c_n_max"] / 10 ** 6,
                  }
        if self.use_emulated_basytec:
            self.sent_can_successful = self.emulated_basytec.send_to_emulated_basytec(values, can_id)
        else:
            # encode data packet and send it out via can
            data_out = self.definition.encode_data_for_basytec(can_id, values)
            self.sent_can_successful = self.can.send(can_id, data_out)

    def send_can_sim_values_cathode(self):
        can_id = ID_Sim_to_BaSytec_Kathode
        values = {"pot_p": self.simulation.sim_out_dict["pot_p"],
                  "eta_p": self.simulation.sim_out_dict["eta_p"],
                  "eta_sei_p": self.simulation.sim_out_dict["eta_sei_p"],
                  "delta_c_p_max": self.simulation.sim_out_dict["delta_c_p_max"] / 10 ** 7,
                  }
        if self.use_emulated_basytec:
            self.sent_can_successful = self.emulated_basytec.send_to_emulated_basytec(values, can_id)
        else:
            # encode data packet and send it out via can
            data_out = self.definition.encode_data_for_basytec(can_id, values)
            self.sent_can_successful = self.can.send(can_id, data_out)

    def control_fan(self):
        t1 = self.temp_buffer.get_averages()[0]

        u = self.pid_fan.update(t1)

        self.fan_pwm_value = u
        self.fan_pwm.ChangeDutyCycle(u)

    def update_sim(self):
        if EMULATE_BASYTECH:
            temp_surface = self.emulated_basytec.temp_surface
        else:
            temp_surface = self.temp_buffer.get_averages()[0]

        # starting sim when start bit from BaSyTec goes from 0 to 1 and all init vars are received
        if self.recv.start_sim and not self.simulation.process and self.recv.init_ready:
            self.simulation.start(init_soc=self.recv.soc, init_capacity=self.recv.init_capacity,
                                  init_sei_resistance=self.recv.init_sei_resistance,
                                  init_temp_core=self.recv.init_temp_core,

                                  max_v=self.recv.max_voltage, max_i=self.recv.max_current,
                                  min_pot_n=self.recv.min_pot_n, max_temp=self.recv.max_tempt_core,
                                  # adding label for local logging with init parameters
                                  log_label=
                                  "init_t_core={:4.2f}-max_v={:4.2f}-max_c={:4.1f}-min_pot_n={:3.0f}-max_t_core={:2.0f}"
                                  .format(self.recv.init_temp_core, self.recv.max_voltage, self.recv.max_current,
                                          self.recv.min_pot_n*1000, self.recv.max_tempt_core).replace(" ", "_")
                                  )

        # update sim if already running
        if self.simulation.process and None not in self.recv.__dict__.values():
            self.current_from_sim = self.simulation.update(actual_current=self.recv.current,
                                                           actual_voltage=self.recv.voltage,
                                                           actual_temp_surface=temp_surface)

        # stopping sim when start bit from BaSyTec goes from 1 to 0
        if self.simulation.process and not self.recv.start_sim:
            self.simulation.stop()

    def print_status_new(self):
        # Will generate String and print them
        # colors
        blue = '\033[94m'
        green = '\033[92m'
        fail = '\033[91m'
        end = '\033[0m'

        # generate temp String
        temps = self.temp_buffer.get_averages()
        temp_string = blue + "T_surf={:5.2f}->{:5.2f}°C".format(temps[0], self.pid_fan.set_point) + end

        # generate Simulation string
        if self.simulation.sim_initialized:
            sim_string = ("T_core={:5.2f}->{:5.2f}°C | ".format(self.simulation.sim_out_dict["temp_core"],
                                                                self.simulation.pid_temp_core.set_point) +
                          "V={:5.3f}->{:5.3f}V | ".format(self.simulation.sim_out_dict["V"],
                                                          self.simulation.pid_voltage.set_point / 1000) +
                          "pot_n={:5.1f}->{:5.1f}mV".format(self.simulation.sim_out_dict["pot_n"] * 1000,
                                                            self.simulation.pid_pot_n.set_point))
        else:
            sim_string = "SIM not running"

        # generate CAN strings
        if None in self.recv.__dict__.values():
            can_recv_string = "CAN received: " + fail + " No" + end + "-> Waiting for Values from BaSyTec"
        else:
            can_recv_string = "CAN received: " + green + "Yes" + end + "-> I={:6.3f}A, U={:5.3f}V, SOC={:5.1f}%" \
                .format(self.recv.current, self.recv.voltage, self.recv.soc)

        can_send_string = "CAN sent:" + (green + "Yes" + end if self.sent_can_successful else fail + " No" + end)

        # assemble all strings and print them
        print(temp_string + " | " + sim_string + " | " + can_send_string + " | " + can_recv_string, flush=True)

        # warn if to many threads are opened
        if threading.active_count() > 15:
            print("Warning: Number of Threads is high ==> {}".format(threading.active_count()))

    def exit(self):
        # adding exit handler to stop fan at exit
        print('Exit Test Bench')
        self.fan_pwm.ChangeDutyCycle(0)


if __name__ == '__main__':
    print("DCFC Test Bench - Main Program")
    test_bench = TestBench(emulated_basytec=EMULATE_BASYTECH)
    atexit.register(test_bench.exit)

    # just for testing
    if test_bench.use_emulated_basytec:

        for temp in range(20, 70, 10):
            for min_pot_n in range(50, -10, -10):

                test_bench.emulated_basytec = EmulatedBaSyTec(init_soc=0,
                                                              init_temp_core=temp,
                                                              temp_surface=temp,
                                                              init_capacity=0,
                                                              init_sei_r=0,
                                                              max_v=4.2,
                                                              max_i=20,
                                                              min_pot_n=min_pot_n/1000,
                                                              max_temp=100)

                time.sleep(1)
                test_bench.emulated_basytec.start_sim = 1

                while not test_bench.simulation.sim_initialized:
                    time.sleep(1)

                while test_bench.simulation.sim_out_dict["soc"] < 80 and not test_bench.simulation.crashed:
                    time.sleep(1)

                print("END")
                test_bench.emulated_basytec.start_sim = 0
                test_bench.simulation.crashed = False
                time.sleep(1)
