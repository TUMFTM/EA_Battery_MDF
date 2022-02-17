from configparser import RawConfigParser
import os


def range_of_type(data_type):
    # return value ranger according to data type
    if data_type == "I8":
        return -128, 127

    if data_type == "UI8":
        return 0, 255

    if data_type == "I16":
        return -32768, 32767

    if data_type == "UI16":
        return 0, 65535


def clipping(value, min_max_thresholds, var_name):
    # keep track of already warned signals
    if not hasattr(clipping, "already_warned_dict"):
        clipping.already_warned_dict = {}  # it doesn't exist yet, so initialize it

    # getting thresholds
    lower_thr = min_max_thresholds[0]
    upper_thr = min_max_thresholds[1]

    # store original value to detect clipping
    original_value = value

    # clips value respecting the given upper and lower threshold
    value = lower_thr if value < lower_thr else value
    value = upper_thr if value > upper_thr else value

    clipped = True if original_value != value else False

    if clipped and var_name not in clipping.already_warned_dict:
        print("Warning: Value was clipped before it could be sent by CAN. Check Value / CAN-Definition. "
              "Name={}, Value={}, Clipped={}".format(var_name, original_value, value))
        print("Further warnings of this Signal are now muted")
        clipping.already_warned_dict[var_name] = 1

    return value


class Message:
    """
    Not supported:
    - TX Request
    - Filters
    """

    def __init__(self, config, message_section):
        self.config = config

        # reading the individual config elements for the message and converting data types
        self.id = int(config.get(message_section, "ID"))
        self.nr = int(config.get(message_section, "MSGNR"))
        self.name = config.get(message_section, "Name")
        self.length = int(config.get(message_section, "Datalength"))
        self.direction = config.get(message_section, "Datadir")
        self.tx_period = int(config.get(message_section, "TxPeriod"))
        self.signals = []

        # Check if any unsupported settings are in config and trowing error
        # check that no tx req
        if self.direction == "RXDTXD":
            raise AttributeError("No TX Request supported, please remove TX Request from Message: {}".format(self.name))
        # check that no filters
        if config.get(message_section, "Filter") == "1" or config.get(message_section, "Filter2") == "1":
            raise AttributeError("No Filters supported, please remove Filters from Message: {}".format(self.name))

    def add_signal(self, section):
        # adds a signal object to the message
        self.signals.append(Signal(self.config, section))


class Signal:
    """
    Only big Endian supported
    Only linear
    Only int, uint
    """

    def __init__(self, config, signal_section):
        # reading the individual config elements for the signal and converting data types
        self.name = config.get(signal_section, "Name")
        self.msg_id = int(config.get(signal_section, "MSGID"))
        self.msg_nr = int(config.get(signal_section, "MSGNR"))
        self.start_bit = int(config.get(signal_section, "Start"))
        self.factor = float(config.get(signal_section, "Factor").replace(",", "."))
        self.offset = float(config.get(signal_section, "Offset").replace(",", "."))
        self.signal_id = int(config.get(signal_section, "Datapos"))
        self.format = config.get(signal_section, "Dataformat")
        self.unit = config.get(signal_section, "Unit")
        self.endianness = config.get(signal_section, "Endian")

        # Check if any unsupported settings are in config and trowing error
        # Check that only linear calculation is used
        if config.get(signal_section, "Linear") != "1":
            raise AttributeError("Only linear supported, please set \"{}\" config to linear".format(self.name))

        # # Check that big endian is used
        # if config.get(signal_section, "Endian") != "Big":
        #     raise AttributeError("Only big Endian supported, please set \"{}\" to big Endian".format(self.name))

        # Check that no unsupported data type is used
        if config.get(signal_section, "Dataformat") not in {"I8", "I16", "UI8", "UI16", }:
            raise AttributeError("Only [I8, I16, UI8, UI16] type supported, please adjust in \"{}\" ".format(self.name))


class CanDefinition:
    def __init__(self, cdf_path):
        # reading config file
        self.config = RawConfigParser()
        if os.path.isfile(cdf_path):
            self.config.read(cdf_path)
        else:
            raise FileNotFoundError("Please put valid BaSyTec CAN Definition File in Home folder")

        # reading the individual config elements for the general can settings
        if "B" in self.config.get("General", "Canversion"):
            self.extended_id = True
        else:
            self.extended_id = False
        self.bitrate = int(self.config.get("General", "Baudrate")) * 1000

        # creating emtpy list where all message configs are stored
        self.messages = []

        # remember last read message
        last_message = None

        # going through all sections of config
        for section in self.config.sections():
            if "MSG_" in section:
                last_message = Message(self.config, section)
                self.messages.append(last_message)
            if "SIG_" in section:
                if last_message:
                    last_message.add_signal(section)
                else:
                    raise LookupError("Config parse Error")

    def print_config(self):
        # for debugging
        print("---CAN CONFIG---")
        print("Bitrate:", self.bitrate)
        for message in self.messages:
            print("\nMSG:", message.name, "ID:", message.id, ": ", end="")
            for signal in message.signals:
                print(signal.name, end=", ")

    def print_ranges_and_resolutions(self):
        for message in self.messages:
            print("[{}] Message {} (CAN ID: {}): {}".format(message.direction, message.id, message.id, message.name))
            for signal in message.signals:
                # value = (raw_value - signal.offset) * signal.factor
                min_raw_value = range_of_type(signal.format)[0]
                max_raw_value = range_of_type(signal.format)[1]

                min_value = (min_raw_value - signal.offset) * signal.factor
                max_value = (max_raw_value - signal.offset) * signal.factor
                resolution = signal.factor
                print("\t-{:20}[{:6}]: {:10.5g} | {:10.5g} | {:10}".format(
                    signal.name, signal.unit, min_value, max_value, resolution))

    def encode_data_for_basytec(self, can_id, signal_dict):
        # search for message in config
        message = next((msg for msg in self.messages if msg.id == can_id), None)
        msg_bytes = []

        for signal in message.signals:

            # get value from dict
            value = signal_dict[signal.name]

            # Basytec manual says:
            # The variables will be transferred between the BaSyTec software and hardware as signed 32bit integers
            # in units of 1e-5.
            # Therefore, the maximum range for OSI variables  is about +/-21474 and the resolution is 0.00001.

            value = clipping(value, (-21470, +21470), signal.name)  # with some headroom

            # apply signal calculation and convert to int
            # print(signal.name, value, signal.factor, signal.offset)
            raw_value = int(round((value + signal.offset) / signal.factor))

            # get endianness and make it lowercase for byteorder parameter
            endianness = signal.endianness.lower()

            # stay in range
            raw_value = clipping(raw_value, range_of_type(signal.format), signal.name)

            # check for format
            if signal.format == "I8":
                # add byte(s) to message
                msg_bytes.append(raw_value.to_bytes(1, byteorder=endianness, signed=True))
            if signal.format == "UI8":
                # add byte(s) to message
                msg_bytes.append(raw_value.to_bytes(1, byteorder=endianness, signed=False))
            if signal.format == "I16":
                # add byte(s) to message
                msg_bytes.append(raw_value.to_bytes(2, byteorder=endianness, signed=True))
            if signal.format == "UI16":
                # add byte(s) to message
                msg_bytes.append(raw_value.to_bytes(2, byteorder=endianness, signed=False))

        # assemble message
        return b''.join(msg_bytes)

    def decode_data_from_basytec(self, can_id_dec, can_data):
        # search for message in config
        message = next((msg for msg in self.messages if msg.id == can_id_dec), None)

        # empty dict for storing decoded values
        decoded_dict = {}
        # signal position in can data
        pos = 0

        for signal in message.signals:
            # get endianness and make it lowercase for byteorder parameter
            endianness = signal.endianness.lower()

            # check for format
            if signal.format == "I8":
                # get raw value from can data at current position
                raw_value = int.from_bytes(can_data[pos:pos + 1], byteorder=endianness, signed=True)
                # increment position by size of data type
                pos += 1
            if signal.format == "UI8":
                # get raw value from can data at current position
                raw_value = int.from_bytes(can_data[pos:pos + 1], byteorder=endianness, signed=False)
                # increment position by size of data type
                pos += 1
            if signal.format == "I16":
                # get raw value from can data at current position
                raw_value = int.from_bytes(can_data[pos:pos + 2], byteorder=endianness, signed=True)
                # increment position by size of data type
                pos += 2
            if signal.format == "UI16":
                # get raw value from can data at current position
                raw_value = int.from_bytes(can_data[pos:pos + 2], byteorder=endianness, signed=False)
                # increment position by size of data type
                pos += 2

            # apply signal calculation and convert to int
            value = (raw_value - signal.offset) * signal.factor

            # add value to dict
            decoded_dict[signal.name] = value

        return decoded_dict


if __name__ == '__main__':
    print("CAN Definition - Debug Mode")
    path = r"C:\Users\Andreas\Ausbildung\Studium\02 Master\Masterarbeit\Code\DCFC Test Bench\DCFC_Test_Bench.cdf"
    print(path)
    parser = CanDefinition(path)

    # parser.print_config()
    parser.print_ranges_and_resolutions()

    # print(parser.messages[1].signals[2])

    can_id_test = 1
    values = {"fan_pwm": 29,
              "fan_rpm": -3000,
              "controller_p": -22,
              "controller_i": 30,
              "controller_d": -10,
              }

    for x in range(10):
        # encode data packet and send it out via can
        data_out = parser.encode_data_for_basytec(can_id_test, values)

    # print("\n\n",data_out)

    # data_old=encode_data_for_basytec(1200, 34,  35, 36,  33, 0)
    # data=config.encode_data_for_basytec(1, signal_dict=d)
    # print("\nDATA")
    # # print(data_old)
    # # print(data)
    #
    # data_in=b'\x04\xb0\xaa\xaf\xb4!\x00'
    #
    # dict_in=parser.decode_data_from_basytec(37, data_in)
    # print(dict_in)
