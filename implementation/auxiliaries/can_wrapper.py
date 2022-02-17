#!/usr/bin/env python
# coding: utf-8

print("Importing Modules...")
import can
import os, sys
import subprocess
import math
from time import sleep
from configuration import ID_Values_from_BaSyTec, ID_init_Values_from_BaSyTec, ID_Control_from_BaSyTec

def execute_linux_cmd(command):
    # debug
    # print("Executing command:", command)
    output = os.popen(command).read()
    if output:
        # debug
        # print("Output of executing cmd: {}".format(output))
        pass
    return output


# check for operating system to be windows compatible
if os.name == 'nt':
    hardware_platform = "windows"
    bustype = 'ixxat'
    channel = 0
elif "BCM" in execute_linux_cmd("grep Hardware /proc/cpuinfo"):
    hardware_platform = "raspberry"
    bustype = 'socketcan'
    channel = 'can0'
else:
    hardware_platform = "beaglebone"
    bustype = 'socketcan'
    channel = 'can1'
    # check for root on linux
    if os.getuid() != 0:
        sys.exit('Please run script as admin')

print("Running on:", hardware_platform)

# generate linux setup commands according to platform
if hardware_platform != "windows":
    cmd_define_can1_pins = "config-pin p9.24 can \n" \
                           "config-pin p9.26 can"
    cmd_set_can_up = "sudo ifconfig {} up".format(channel)
    cmd_set_can_down = "sudo ifconfig {} down".format(channel)
    # cmd_set_can_up_and_bitrate = "sudo ip link set {} up type can bitrate ".format(channel)
    cmd_set_can_bitrate = "sudo ip link set {} type can bitrate ".format(channel)
    cmd_get_can_bitrate = "ip -det link show " + channel + " | grep bitrate | awk '{print $2}'"


class CAN:
    def __init__(self, bitrate, extended_id=False):

        self.bitrate = bitrate
        self.is_extended_id = extended_id

        # when running on beaglebone, can pins have to be defined
        if hardware_platform == "beaglebone":
            if subprocess.run(["config-pin", "-q p9.24"], stdout=subprocess.PIPE).stdout != b'P9_24 Mode: can\n':
                execute_linux_cmd(cmd_define_can1_pins)
                print("Can Pins configured")

        # when running on Linux CAN has to be initialized and set to up
        if hardware_platform != "windows":
            self.set_can_bitrate(bitrate)
            self.set_can("up")

        # creating Bus object regarding the settings
        self.bus = can.interface.Bus(bustype=bustype, channel=channel)
        self.can_up = True

    def get_can_bitrate(self):
        if hardware_platform == "windows":
            print("Bitrate can't be read on windows")
        bitrate = execute_linux_cmd(cmd_get_can_bitrate)
        if bitrate:
            self.bitrate = int(bitrate)
            return int(bitrate)
        else:
            return 0

    def set_can_bitrate(self, bitrate):
        if hardware_platform == "windows":
            print("Bitrate can't be changed on windows, nothing changed")
        # when running on Linux
        else:
            # check if bitrate already matches and has not to be changed
            if self.get_can_bitrate() != bitrate:
                # trying to set bitrate and can to UP
                if "busy" in execute_linux_cmd(cmd_set_can_bitrate + str(bitrate)):
                    print("Bitrate could not be set, disable can before changing bitrate")
                else:
                    print("Bitrate set to {} and can set to up".format(bitrate))
            else:
                print("Bitrate already set to {}".format(bitrate))

    def set_can(self, state):
        if hardware_platform == "windows":
            print("CAN state can't be changed on windows, nothing changed")
        else:
            if state == "up":
                execute_linux_cmd(cmd_set_can_up)
                self.can_up = True
                print("can set to up")
            if state == "down":
                execute_linux_cmd(cmd_set_can_down)  # CAN DOWN WILL CRASH IXXAT DONGLE TOOL
                self.can_up = False
                print("can set to down")

    def send(self, can_id_dec, data):
        # check if can is up
        if not self.can_up:
            self.set_can("up")

        # variable to determine whether sending was successful
        success = True

        # create message
        msg = can.Message(arbitration_id=can_id_dec, data=data, is_extended_id=self.is_extended_id)

        # trying to send message on bus
        try:
            self.bus.send(msg)
            if __name__ == '__main__':
                print("Message \"{}\" with ID: \"{}\" sent on {}".format(data, id, self.bus.channel_info))
        except can.CanError as error:
            success = False
            # only print error when running in main (most likely a buffer error)
            if __name__ == '__main__':
                print("Message NOT sent, Error: {}".format(error))

        return success

    def receive(self):
        # check if can is up
        if not self.can_up:
            self.set_can("up")

        # try to get a message, only one message will be received
        msg = self.bus.recv(timeout=0.0)
        try:
            # ignore received message if it just contains zeros except ID_init_Values_from_BaSyTec where all zero is possible (init msg)
            if msg.arbitration_id == ID_Values_from_BaSyTec or msg.arbitration_id == ID_init_Values_from_BaSyTec or msg.arbitration_id == ID_Control_from_BaSyTec:
                return msg.data, msg.arbitration_id
            else:
                raise AttributeError
        # catch Error if nothing is received
        except AttributeError:
            return None, 0

    def send_temps(self, get_averages_function):
        # METHOD GOT REPLACED BY CAN DEFINITION READER
        temps = get_averages_function()
        fan_speed = 101
        data = encode_data_for_basytec(0, temps[0], temps[1], temps[2], int(fan_speed), 123,
                                       status=0b00000010)
        self.send(0x01, data)


def clipping(values, lower_thr, upper_thr):
    if not isinstance(values, list):
        values = [values]
        no_list = True
    else:
        no_list = False

    for i in range(len(values)):
        values[i] = lower_thr if values[i] < lower_thr else values[i]
        values[i] = upper_thr if values[i] > upper_thr else values[i]

    if no_list:
        return values[0]
    else:
        return values


def encode_data_for_basytec(set_current_mA, cell_temp_left, cell_temp_middle, cell_temp_right, fan_speed, peltier_power,
                            status=0b00000000):
    # METHOD GOT REPLACED BY CAN DEFINITION READER

    # sanity checks

    cell_temp_left, cell_temp_middle, cell_temp_right = clipping([cell_temp_left, cell_temp_middle,
                                                                  cell_temp_right], 0, 255 / 5)
    fan_speed, peltier_power, status = clipping([fan_speed, peltier_power, status], 0, 255)

    # Basytec manual:
    # The variables will be transferred between the BaSyTec software and hardware as signed 32bit integers
    # in units of 1e-5. Therefore, the maximum range for OSI variables  is about +/-21474 and the resolution is 0.00001.

    set_current_mA = clipping(set_current_mA, -21000, +21000)

    byte_0_1 = int(round(set_current_mA)).to_bytes(2, byteorder='big', signed=True)
    byte_2 = (int(round(cell_temp_left * 5))).to_bytes(1, byteorder='big')
    byte_3 = (int(round(cell_temp_middle * 5))).to_bytes(1, byteorder='big')
    byte_4 = (int(round(cell_temp_right * 5))).to_bytes(1, byteorder='big')
    byte_5 = fan_speed.to_bytes(1, byteorder='big')
    byte_6 = peltier_power.to_bytes(1, byteorder='big')
    byte_7 = status.to_bytes(1, byteorder='big')

    return byte_0_1 + byte_2 + byte_3 + byte_4 + byte_5 + byte_6 + byte_7


def decode_data_from_basytec(data):
    # METHOD GOT REPLACED BY CAN DEFINITION READER
    soc = int.from_bytes(data[0:2], "big", signed=False) * 0.01
    act_current = int.from_bytes(data[2:4], "big", signed=True)
    act_voltage = int.from_bytes(data[4:6], "big", signed=False)
    set_temp_basytec = int.from_bytes(data[6:7], "big", signed=False) * 0.2
    unused = int.from_bytes(data[7:8], "big", signed=False)

    return {"SOC": soc, "act_current": act_current, "act_voltage": act_voltage, "set_temp_basytec": set_temp_basytec}


def create_dummy_send_data():
    if not hasattr(create_dummy_send_data, "counter"):
        create_dummy_send_data.counter = 0  # if it doesn't exist, initialize it
    create_dummy_send_data.counter += 1
    return encode_data_for_basytec(set_current_mA=int(math.sin(create_dummy_send_data.counter / 20) * 2000),
                                   cell_temp_left=27, cell_temp_middle=28, cell_temp_right=26,
                                   fan_speed=126, peltier_power=201, status=0b00000000)


def test(mode):
    can_object = CAN(250000)

    counter = 0
    if mode == "recv":
        print("Waiting for message")
        while 1:
            data = can_object.receive()
            if data:
                counter += 1
                print(decode_data_from_basytec(data), counter)
            sleep(0.1)

    else:
        while 1:
            dummy_data = create_dummy_send_data()
            can_object.send(0x01, dummy_data)
            sleep(1)


if __name__ == '__main__':
    print("basytec can in test-mode")

    test_mode = "send"
    # test_mode = "recv"
    test(test_mode)
