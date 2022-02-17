from configuration import *

class EmulatedBaSyTec:
    def __init__(self, init_soc=0, init_capacity=0, init_sei_r=0, init_temp_core=20, temp_surface=20,
                 max_v=4.2, max_i=25, min_pot_n=0.020, max_temp=70):
        # vars

        # status
        self.init_soc = init_soc
        self.init_capacity = init_capacity
        self.init_sei_r = init_sei_r
        self.init_temp_core = init_temp_core
        self.temp_surface = temp_surface
        self.max_v = max_v
        self.max_i = max_i
        self.max_temp = max_temp
        self.min_pot_n = min_pot_n

        self.start_sim = 0
        self.set_temp_fan = 26  # keep fan off

        # Can 1
        self.fan_pwm = 0
        self.fan_rpm = 0
        self.controller_p = 0
        self.controller_i = 0
        self.controller_d = 0

        # Can 2
        self.t_a = 0
        self.t_b = 0
        self.t_c = 0
        self.t_status = 0

        # Can 3
        self.voltage_sim = 0
        self.soc_sim = 0
        self.temp_core_sim = 0
        self.t_solve = 0
        self.set_current_sim = 0

        # Can 4
        self.pot_n = 0
        self.eta_n = 0
        self.eta_sei_n = 0
        self.delta_c_n_max = 0

        # Can 5
        self.pot_p = 0
        self.eta_p = 0
        self.eta_sei_p = 0
        self.delta_c_p_max = 0

    def send_to_emulated_basytec(self, values, can_id):

        if can_id == ID_Fan_Controller_to_BaSyTec:
            self.fan_pwm = values["fan_pwm"]
            self.fan_rpm = values["fan_rpm"]
            self.controller_p = values["controller_p"]
            self.controller_i = values["controller_i"]
            self.controller_d = values["controller_d"]

        if can_id == ID_Temps_to_BaSyTec:
            self.t_a = values["t_a"]
            self.t_b = values["t_b"]
            self.t_c = values["t_c"]
            self.t_status = values["t_status"]

        if can_id == ID_Sim_to_BaSyTec:
            self.voltage_sim = values["voltage_sim"]
            self.soc_sim = values["soc_sim"]
            self.temp_core_sim = values["temp_core_sim"]
            self.t_solve = values["t_solve"]
            self.set_current_sim = values["set_current_sim"]

        if can_id == ID_Sim_to_BaSyTec_Anode:
            self.pot_n = values["pot_n"]
            self.eta_n = values["eta_n"]
            self.eta_sei_n = values["eta_sei_n"]
            self.delta_c_n_max = values["delta_c_n_max"]

        if can_id == ID_Sim_to_BaSytec_Kathode:
            self.pot_p = values["pot_p"]
            self.eta_p = values["eta_p"]
            self.eta_sei_p = values["eta_sei_p"]
            self.delta_c_p_max = values["delta_c_p_max"]

        return True

    def receive_from_emulated_basytec(self):

        data = {
            # MSG 1
            "actual_soc": self.soc_sim,
            "actual_current": self.set_current_sim,
            "actual_voltage": self.voltage_sim,
            # MSG 2
            "init_soc": self.init_soc,
            "init_capacity": self.init_capacity,
            "init_sei_r": self.init_sei_r,
            "init_temp_core": self.init_temp_core,
            # MSG 3
            "max_current": self.max_i,
            "max_voltage": self.max_v,
            "max_temp_core": self.max_temp,
            "min_pot_n": self.min_pot_n,
            "start_simulation": self.start_sim,
            "set_temp_fan": self.set_temp_fan}

        return data
