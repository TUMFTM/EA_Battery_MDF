###Configuration script###

# 0. If multiple Test Benches are used within one CAN-Bus it is required to asign it different numbers
# Currently there are 6 different instances allowed ( if you assign a number outside 1-6 it wi9ll be configured as Instance 1
TEST_BENCH_NR = 1


# 1. Paths of related files

# Path to CAN Config (*.cdf).
if(TEST_BENCH_NR == 1):
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_1.cdf"
elif(TEST_BENCH_NR == 2):
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_2.cdf"
elif(TEST_BENCH_NR == 3):
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_3.cdf"
elif(TEST_BENCH_NR == 4):
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_4.cdf"
elif(TEST_BENCH_NR == 5):
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_5.cdf"
elif(TEST_BENCH_NR == 6):
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_6.cdf"
else:
    CONFIG_PATH = r"../auxiliaries/cdf/DCFC_Test_Bench_1.cdf"
    
# Path and name of generated executable (*.elf) from Simulink
PATH_TO_ELF = r"../model_builds"
NAME_OF_ELF = r"spmet_30032021_raspberry_live_update_R19b" + ".elf"
#MATLAB_PATH_PREFIX = "Matlab_builds/MATLAB_ws/R2019b/"  # the path from where the Windows path is recreated
MATLAB_PATH_PREFIX = ""

# 2. Fan Controller

FAN_PID_CONFIG = {"isFan": "", "inverse": True, "Name": "Arctic F8", "u_min": 0, "u_max": 100, "p": 3, "i": 1, "d": 0}
# FAN_PID_CONFIG = {"isFan": "", "inverse": True, "Name": "EBM Pabst", "u_min": 6, "u_max": 100, "p": 6, "i": 2, "d": 0}

# 3. Model-based current control 

PID_CONFIG_POT_N = {"inverse": True, "Name": "Anode Potential", "u_min": 0, "u_max": 25, "p": 0.1, "i_down": 0.05, "i_up": 0.05, "d": 0.001}
#PID_CONFIG_POT_N = {"inverse": True, "Name": "Anode Potential", "u_min": 0, "u_max": 25, "p": 0, "i_down": 3, "i_up": 1, "d": 0}
PID_CONFIG_VOLTAGE = {"inverse": False, "Name": "Constant Voltage", "u_min": 0, "u_max": 25, "p": 0, "i_down": 3, "i_up": 1, "d": 0}
PID_CONFIG_TEMP = {"inverse": False, "Name": "Constant Temp", "u_min": 0, "u_max": 25, "p": 50, "i_down": 0, "i_up": 0, "d": 0}

# 4. Time periods in ms. NOTE: absolute time will drift over time, do not use too small intervals.

acquire_temps_period = 100
print_status_period = 100
control_fan_period = 100
can_receive_period = 5
can_send_temps_period = 1000
can_send_sim_period = 100
update_sim_period = 50

average_window_time = 2000 # Temperature moving average time

# 5. CAN-IDs

if(TEST_BENCH_NR == 1):
    ID_Fan_Controller_to_BaSyTec = 1
    ID_Temps_to_BaSyTec = 2
    ID_Sim_to_BaSyTec = 3
    ID_Sim_to_BaSyTec_Anode = 4
    ID_Sim_to_BaSytec_Kathode = 5
    ID_Values_from_BaSyTec = 10
    ID_init_Values_from_BaSyTec = 11
    ID_Control_from_BaSyTec = 12
elif(TEST_BENCH_NR == 2):
    ID_Fan_Controller_to_BaSyTec = 513
    ID_Temps_to_BaSyTec = 514
    ID_Sim_to_BaSyTec = 515
    ID_Sim_to_BaSyTec_Anode = 516
    ID_Sim_to_BaSytec_Kathode = 517
    ID_Values_from_BaSyTec = 522
    ID_init_Values_from_BaSyTec = 523
    ID_Control_from_BaSyTec = 524
elif(TEST_BENCH_NR == 3):
    ID_Fan_Controller_to_BaSyTec = 769
    ID_Temps_to_BaSyTec = 770
    ID_Sim_to_BaSyTec = 771
    ID_Sim_to_BaSyTec_Anode = 772
    ID_Sim_to_BaSytec_Kathode = 773
    ID_Values_from_BaSyTec = 778
    ID_init_Values_from_BaSyTec = 779
    ID_Control_from_BaSyTec = 780
elif(TEST_BENCH_NR == 4):
    ID_Fan_Controller_to_BaSyTec = 1025
    ID_Temps_to_BaSyTec = 1026
    ID_Sim_to_BaSyTec = 1027
    ID_Sim_to_BaSyTec_Anode = 1028
    ID_Sim_to_BaSytec_Kathode = 1029
    ID_Values_from_BaSyTec = 1034
    ID_init_Values_from_BaSyTec = 1035
    ID_Control_from_BaSyTec = 1036
elif(TEST_BENCH_NR == 5):
    ID_Fan_Controller_to_BaSyTec = 1281
    ID_Temps_to_BaSyTec = 1282
    ID_Sim_to_BaSyTec = 1283
    ID_Sim_to_BaSyTec_Anode = 1284
    ID_Sim_to_BaSytec_Kathode = 1285
    ID_Values_from_BaSyTec = 1290
    ID_init_Values_from_BaSyTec = 1291
    ID_Control_from_BaSyTec = 1292
elif(TEST_BENCH_NR == 6):
    ID_Fan_Controller_to_BaSyTec = 1537
    ID_Temps_to_BaSyTec = 1538
    ID_Sim_to_BaSyTec = 1539
    ID_Sim_to_BaSyTec_Anode = 1540
    ID_Sim_to_BaSytec_Kathode = 1541
    ID_Values_from_BaSyTec = 1546
    ID_init_Values_from_BaSyTec = 1547
    ID_Control_from_BaSyTec = 1548
else:
    ID_Fan_Controller_to_BaSyTec = 1
    ID_Temps_to_BaSyTec = 2
    ID_Sim_to_BaSyTec = 3
    ID_Sim_to_BaSyTec_Anode = 4
    ID_Sim_to_BaSytec_Kathode = 5
    ID_Values_from_BaSyTec = 10
    ID_init_Values_from_BaSyTec = 11
    ID_Control_from_BaSyTec = 12
    

# 6. Emulated Basytec: Set this Flag to use a virtual basytec and not CAN by placing a empty file EMULATE_BASYTEC next to the main script

import os
EMULATE_BASYTECH = os.path.isfile("EMULATE_BASYTEC")  # this file MUST NOT be present for real testing!!!
