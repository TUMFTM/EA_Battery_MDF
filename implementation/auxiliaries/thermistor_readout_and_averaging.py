import math
import time
import numpy as np
import Adafruit_ADS1x15


def voltage_to_temp(u_adc, u_supply, r_divider):
    # constants for calculation
    kelvin = 273.15
    b = 3988
    r_0 = 5000
    t_0 = 25

    # sometimes the ADC reads 0 or -1, in this case a temp of 25°C is returned which gets smoothed out by the buffer
    if u_adc <= 0 or u_supply <= 0:
        return 25

    # calculation of thermistor resistance
    if u_supply - u_adc < 0.100:  # when probe is not connected
        return 0
    r_th = r_divider * (u_adc / (u_supply - u_adc))

    # converting thermistors resistance to temperature using Steinhart-Hart Equation
    t = b / (math.log(r_th / r_0) + (b / (t_0 + kelvin))) - kelvin
    return t


class Buffer:
    def __init__(self, buffer_size):
        self.number_sensors = 3
        self.buffer = np.zeros((self.number_sensors, buffer_size))  # init buffer
        self.buffer_size = buffer_size
        self.buffer_pos = 0  # initialize buffer position to 0
        self.number_filled = 0  # to mitigate ramp up at beginning
        self.last_warn_time = 0

        # ADC Setup
        try:
            self.adc = Adafruit_ADS1x15.ADS1115()  # Create an ADS1115 ADC (16-bit) instance.
        except FileNotFoundError:
            print("Warning: No ADC found. Starting testing mode with all T=20°C")
            self.adc = None

    def read_temp(self):
        if not self.adc:
            return

        # CALIBRATION DATA:
        # r_divider = [4667.2, 4668.5, 4673.4]  # specific measured resistance of each voltage divider resistor
        r_divider = [4667.2, 4620.0, 4673.4]  # R2 was adjusted through real temp measurements

        # read voltage reference (3.3V of the Pi) for compensation
        # 4th channel is connected to 3.3V supply of thermistor network
        u_supply = self.adc.read_adc(3, gain=1) / 32767 * 4.096  # gain = 1 leads to range +/-4.096V

        # sometimes ADC reads zero, then a supply of 3.3V is assumed to minimize error
        if u_supply < 2.0:
            u_supply = 3.3

        # check if warning was present to prevent overflodding with warnings
        warn_present = False

        # read all three sensor values
        for sensor_id in range(self.number_sensors):
            # Read the specified ADC channel and converting it to voltage
            # reverse sensor id, because Channel_A = ADC_2, Channel_B = ADC_1, Channel_C = ADC_0,
            voltage = self.adc.read_adc(2 - sensor_id, gain=1) / 32767 * 4.096  # gain = 1 leads to range +/-4.096V

            # check if probe is not connected and only warn every 5s
            if u_supply - voltage < 0.100 and time.time() - self.last_warn_time > 5:
                print("Warning: Probe {} disconnected!".format([["A", "B", "C"][sensor_id]]))
                warn_present = True

            # converting voltage to temperature and feeding it to buffer
            self.buffer[sensor_id, self.buffer_pos] = voltage_to_temp(voltage, u_supply, r_divider[sensor_id])

        # set new time if warning was displayed
        if warn_present:
            self.last_warn_time = time.time()

        # incrementing buffer position where values are stored
        self.buffer_pos += 1
        #  repeat filling buffer at start
        if self.buffer_pos >= self.buffer_size:
            self.buffer_pos = 0

        # incrementing number filled
        self.number_filled += 1
        if self.number_filled >= self.buffer_size:
            self.number_filled = self.buffer_size

    def get_averages(self):
        if not self.adc:
            return [25]*self.number_sensors

        # prevent division by 0
        self.number_filled = self.number_filled if self.number_filled > 0 else 1
        # creating empty array according to sensor count
        temps = [0] * self.number_sensors
        # calculate moving average for each sensor
        for sensor_id in range(self.number_sensors):
            temps[sensor_id] = np.sum(self.buffer[sensor_id][:self.number_filled]) / self.number_filled
        return temps

    def print_averages(self):
        print("T1: {:.2f}°C, T2: {:.2f}°C, T3: {:.2f}°C".format(*self.get_averages()))
