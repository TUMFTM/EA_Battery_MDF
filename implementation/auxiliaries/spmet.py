import subprocess
import re
import atexit
import time
import os
from collections import OrderedDict
from pid import Controller
import csv
from configuration import *

# Controller parameters can now be configured in configuration.py

def get_time():
    # could be used to speed up time for testing
    speed_up_factor = 1
    return time.time() * speed_up_factor


class SPMeT:
    def __init__(self, path_elf):
        # init parameters
        self.path_elf = path_elf
        self.time_start = 0.0
        self.time_step = 0.0
        self.process = None
        self.log_file = None
        self.log_writer = None
        self.local_log = False
        self.crashed = False
        self.sim_initialized = False

        # input for simulation
        self.init_soc = 0
        self.init_capacity = 0  # sending 0 makes Simulink use standard values
        self.init_sei_resistance = 0  # sending 0 makes Simulink use standard values
        self.temp_surface = 20
        self.actual_current = 0

        # output from simulation
        self.sim_out_dict = OrderedDict()
        self.sim_out_dict["t"] = 0.0  # to keep time at first place

        # init controllers
        self.pid_pot_n = Controller(PID_CONFIG_POT_N, init_time=get_time())
        self.pid_voltage = Controller(PID_CONFIG_VOLTAGE, init_time=get_time())
        self.pid_temp_core = Controller(PID_CONFIG_TEMP, init_time=get_time())

    def start(self, init_soc, init_capacity, init_sei_resistance, init_temp_core,
              max_v, max_i, min_pot_n, max_temp, log_label):
        # write init parameters to simulation
        self.init_soc = init_soc
        self.init_capacity = init_capacity
        self.init_sei_resistance = init_sei_resistance
        self.temp_surface = init_temp_core  # this works because model initializes the core with surface temp at t=0
        self.time_start = get_time()

        # state variable
        self.crashed = False

        # give set_points to controllers and set maximum current
        self.pid_pot_n.set_point = min_pot_n * 1000
        self.pid_voltage.set_point = max_v * 1000
        self.pid_temp_core.set_point = max_temp
        self.pid_pot_n.u_max = max_i
        self.pid_voltage.u_max = max_i
        self.pid_temp_core.u_max = max_i

        # print initialization values
        print("Model initialized with init_soc={}, init_capacity={}, init_sei_resistance={}, init_temp_core={}".
              format(init_soc, init_capacity, init_sei_resistance, init_temp_core))

        # stat simulation
        self.process = subprocess.Popen(self.path_elf, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                        stdin=subprocess.PIPE)
        # first communication for init
        self.communicate()

        # initialize logging
        self.log_init(suffix=log_label)

    def write_to_process(self, write_value):
        self.process.stdin.write(str(write_value).encode('utf-8') + b"\n")
        self.process.stdin.flush()
        # print("To Simulink:", write_value)

    def read_from_process(self):
        output = self.process.stdout.readline().decode("utf-8")
        # print("From Simulink:", repr(output))
        return output

    def communicate(self):
        if self.process is None:
            raise AttributeError("Simulation not started")

        # set all dict values to -1.0 for sanity check
        sim_out_dict_temp = OrderedDict.fromkeys(self.sim_out_dict, -1.0)
        last_output = ""

        for loop in range(9):  # range = number of expected queries per cycle plus margin

            # read line from simulink output, this waits until simulink responds
            # print("wait for read-line")
            output = self.read_from_process()
            if "init_soc" in output:
                self.write_to_process(self.init_soc)
            elif 'init_capacity' in output:
                self.write_to_process(self.init_capacity)
            elif 'init_sei_resistance' in output:
                self.write_to_process(self.init_sei_resistance)
            elif 'actual_current' in output:
                self.write_to_process(self.actual_current)
            elif 'temp_surface' in output:
                self.write_to_process(self.temp_surface)
            elif 't_real' in output:
                self.write_to_process(get_time() - self.time_start)
            elif "Starting" in output:
                print("New Instance of Simulation started")
                pass
            elif "OUT_STRING" in output:
                last_output = output
                sim_out_matches = re.findall(r"(\w+)=(-?\d+.\d+),?\s*", output)
                if sim_out_matches:
                    for match in sim_out_matches:
                        sim_out_dict_temp[match[0]] = float(match[1])
                else:
                    print("No Regex Match in:\n", output)
                break
            else:
                print("Warning: Unexpected output from Simulink: {}".format(output))

        # sanity check
        if 0 <= sim_out_dict_temp["V"] < 4.5:
            self.sim_out_dict = sim_out_dict_temp
            self.sim_initialized = True
        else:
            self.crashed = True
            print("Warning: Model output outside boundaries, it probably crashed. Last output was: {}"
                  .format(last_output))
            self.stop()

        # adding values which are not provided by simulink for logging(matching output of BaSyTec)
        self.sim_out_dict["Time"] = get_time() - self.time_start
        self.sim_out_dict["t_step"] = get_time() - self.time_step
        self.sim_out_dict["min_pot_n"] = self.pid_pot_n.set_point
        self.sim_out_dict["max_temp_core"] = self.pid_temp_core.set_point
        self.sim_out_dict["max_voltage"] = self.pid_voltage.set_point
        self.sim_out_dict["I"] = self.actual_current
        self.sim_out_dict["t_a"] = self.temp_surface

    def update(self, actual_current, actual_temp_surface, actual_voltage):
        # save start-time of step
        self.time_step = get_time()

        # clip current to positive values if soc is low to prevent model from crashing
        if self.sim_initialized and self.sim_out_dict["soc"] < 1 and actual_current < 0:
            print("Warning: Current was clipped to positive value because soc is low (prevent model from crashing)")
            actual_current = 0

        # give current (from BaSyTec) to simulation
        self.actual_current = actual_current

        # give measured surface temperature
        self.temp_surface = actual_temp_surface

        # run simulation step
        self.communicate()

        # log state
        self.log_step()

        # print status
        # print("Pot_n", self.pid_pot_n.get_status(), "V:", self.pid_voltage.get_status(),
        #       "Temp:", self.pid_temp_core.get_status())

        # evaluate current controller and store in intermediate variable
        set_current_pot_n = self.pid_pot_n.update(self.sim_out_dict["pot_n"] * 1000, time_at_update=get_time())
        set_current_voltage = self.pid_voltage.update(actual_voltage * 1000, time_at_update=get_time())
        set_current_temp_core = self.pid_temp_core.update(self.sim_out_dict["temp_core"], time_at_update=get_time())

        # return minimum current to leave
        return set_current_pot_n  # min(set_current_pot_n, set_current_voltage, set_current_temp_core)

    def log_init(self, suffix="spmet_log"):
        # initializing csv logging
        timestamp = time.strftime("%Y%m%d-%H%M%S_")
        # create log folder if not existent
        if not os.path.exists('spmet_log'):
            os.makedirs('spmet_log')

        # opening csv file and defining the header
        self.log_file = open(r"spmet_log/" + timestamp + suffix + '.csv', mode='w')
        self.log_writer = csv.writer(self.log_file, delimiter=';', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        self.log_writer.writerow(list(self.sim_out_dict.keys()))

    def log_step(self):
        # write data to csv (and only when sim is running)
        if self.sim_initialized:
            self.log_writer.writerow(list(self.sim_out_dict.values()))

    def print_status(self):
        sim_out_dict_copy = OrderedDict(self.sim_out_dict)
        # adjust dimension for better readability
        sim_out_dict_copy["pot_n"] = sim_out_dict_copy["pot_n"] * 1000
        sim_out_dict_copy["pot_p"] = sim_out_dict_copy["pot_p"] * 1000
        sim_out_dict_copy["t_solve"] = sim_out_dict_copy["t_solve"] * 1000
        sim_out_dict_copy["t_step"] = sim_out_dict_copy["t_step"] * 1000

        # print data
        print("I={:6.3f}A (u={:5.1f}, p={:6.1f}, i={:5.1f}, d={:5.1f}) ) | "
              "U={V:5.3f}V , T={temp_core:5.2f}C, SOC={soc:7.3f}%, Pot_n={pot_n:7.3f}mV, Pot_p={pot_p:7.3f}mV,"
              " t_solve={t_solve:5.2f}ms, t_step={t_step:5.2f}ms, t={t:7.3f}s"
              .format(self.actual_current, self.pid_pot_n.u, self.pid_pot_n.p_value, self.pid_pot_n.i_value,
                      self.pid_pot_n.d_value, **sim_out_dict_copy))

    def stop(self):
        self.log_file.close()
        self.sim_initialized = False

        if self.process is not None:
            self.process.kill()
            self.process = None
            print("SPMET Process killed")


if __name__ == '__main__':
    print("SPMeT - Test Mode")

    path_to_simulink_elf = os.path.join(MATLAB_PATH_PREFIX, PATH_TO_ELF, NAME_OF_ELF) \
        .replace("\\", "/").replace(" ", "_").replace("/C:/", "/C/")
    spmet = SPMeT(path_elf=path_to_simulink_elf)

    spmet.start(init_soc=0, init_capacity=0, init_sei_resistance=0, init_temp_core=20,
                max_v=4.2, max_i=25, min_pot_n=0.020, max_temp=70,
                log_label="SOC0-init_core20-max_v4.2-max_i25-min_pot_n50-max_temp60")
    atexit.register(spmet.stop)

    spmet.temp_surface = 20

    current_from_basytec = 0
    time_step = 0

    # setup and start schedulers
    # self.scheduler_acquire_temps = Scheduler(self.acquire_temps_period, self.temp_buffer.read_temp)

    while True:

        # stop simulation if soc=100 reached or when simulation crashes
        if spmet.sim_out_dict["soc"] >= 100 or spmet.crashed:
            break

        # evaluate simulation and controller every x seconds
        if get_time() - time_step > 0.100:
            # save start-time of step
            time_step = get_time()

            # run simulation step + assuming basytec = G(s) = 1
            current_from_basytec = spmet.update(actual_current=current_from_basytec,
                                                actual_temp_surface=spmet.temp_surface,
                                                actual_voltage=spmet.sim_out_dict["V"])

            print("Pot_n", spmet.pid_pot_n.get_status(), "V:", spmet.pid_voltage.get_status(),
                  "Temp:", spmet.pid_temp_core.get_status())
            spmet.print_status()
