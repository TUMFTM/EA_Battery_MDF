import time


class Controller:
    def __init__(self, config, init_time=None):

        self.gain_p = config["p"]
        # beeing as compatible as possible for i_up / down or single i value
        if "i_down" in config and "i_up" in config:
            self.gain_i_down = config["i_down"]
            self.gain_i_up = config["i_up"]
        else:
            self.gain_i_down = config["i"]
            self.gain_i_up = config["i"]
        self.gain_d = config["d"]

        self.is_fan = True if "isFan" in config else False
        self.inverse = config["inverse"]

        # allow modified time for init
        if not init_time:
            init_time = time.time()
        self.last_update_time = init_time

        # init all values
        self.p_value = 0
        self.i_value = 0
        self.d_value = 0

        self.u_min = config["u_min"]  # some fans only start at a certain duty cycle
        self.u_max = config["u_max"]  # to limit fan power

        self.set_point = 0
        self.actual_value = 0

        self.integrator = 0
        self.last_error = 0
        self.integrating_up = True
        self.integrating_down = True

        self.e = 0
        self.u = 0

    def update(self, actual_value, time_at_update=None):

        # allow modified time for update
        if not time_at_update:
            time_at_update = time.time()

        self.actual_value = actual_value

        # calculate error e
        self.e = self.set_point-actual_value
        if self.inverse:
            self.e = -self.e

        # calc delta_t for I and D
        delta_t = time_at_update-self.last_update_time
        self.last_update_time = time_at_update

        # calc integrator if not limited limiting
        if self.integrating_up and self.e > 0:
            self.integrator = self.integrator + self.e * delta_t * self.gain_i_up
        if self.integrating_down and self.e < 0:
            self.integrator = self.integrator + self.e * delta_t * self.gain_i_down

        # limit integrator according to u_max
        if self.integrator > self.u_max:
            self.integrator = self.u_max

        # calc PID values
        self.i_value = self.integrator
        self.p_value = self.e * self.gain_p
        self.d_value = (self.e - self.last_error) / delta_t * self.gain_d

        # storing last error
        self.last_error = self.e

        # calculating u (output)
        self.u = self.p_value + self.i_value + self.d_value + self.u_min

        # limit u and setting flags to prevent wind up
        if self.u >= self.u_max:
            self.u = self.u_max
            self.integrating_up = False
            self.integrating_down = True
        elif self.u < self.u_min:
            self.u = self.u_min
            self.integrating_up = True
            self.integrating_down = False
            # as the fan can produce negative u, integrator gets reset to mitigate undershoot
            if self.is_fan:
                self.integrator = 0
                self.u = 0
        else:
            self.integrating_up = True
            self.integrating_down = True

        return self.u

    def get_status(self):
        # print out values
        return "{:5.2f}=>{:5.2f} u={:5.2f} e={:5.2f} p={:6.1f}, i={:5.1f}, d={:5.1f}"\
            .format(self.actual_value, self.set_point, self.u, self.e, self.p_value, self.i_value, self.d_value)
