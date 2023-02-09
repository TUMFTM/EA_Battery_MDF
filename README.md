# Model deployment framework (MDF) for real-time investigation and usage of battery models on CAN-capable test benches

This repository provides a framework and one-stop toolchain for lithium-ion battery model deployment in CAN-capable test benches.
It can be used, e.g., for investigation of model-based fast charging strategies and other transient investigations in the field of lithium-ion batteries.
The provided framework contains a running example with the lithium-ion battery model of a Sony US18650VTC5A cell provided **[in a previous repository](https://github.com/TUMFTM/EA_Battery_SPMparameterization)**.

The model deployment framework (MDF) is developed and published by

[Nikolaos Wassiliadis](mailto:nikolaos.wassiliadis@tum.de),<br/>
**[Institute of Automotive Technology](https://www.mos.ed.tum.de/mos/startseite/)**,<br/>
**[Technical University of Munich, Germany](https://www.tum.de/nc/en/)**,<br/>
https://doi.org/10.1016/j.jpowsour.2022.232586.

## Features
- One-stop toolchain for deployment of Matlab/Simulink-based lithium-ion battery models in real-time in a lab environment
- Useful tools for successful communication with commercial battery test systems from an embedded system (e.g., RP) via a CAN network

## Usage of the battery model

We are very happy if you choose this framework for your projects and provide all updates under GNU LESSER GENERAL PUBLIC LICENSE Version 3 (29 June 2007).
Please refer to the license file for any further questions about incorporating this battery model into your projects.
We are looking forward to hearing your feedback and kindly ask you to share bugfixes, improvements and updates on the parameterization or implementation.

## Requirements

The framework was created with the following hardware:

| Name | Function |
|---|---|
| Raspberry Pi 3 Model B+ | Embedded hardware |
| CAN/RS485 CAN Head with MCP2515 | CAN interface to embedded hardware|
| BaSyTec XCTS-50 | Battery cycler |
| IXXAT USB-to-CAN compact  | CAN interface to cycler |

The framework was created with the following software:
| Name | Function |
|---|---|
| Matlab/Simulink 2020b  | Model deployment |
| Python 3  | C-code interface/wrapper |

The underlying framework was used for extended temperature control. If similar investigations are planned, the following is required:
| Name | Function |
|---|---|
| Digital ADC Breakout-Board ADS1115 | ADC for extended temperature sensing |
| NTC sensors of type B57861S0502 by TDK | Temperature sensors for the lihtium-ion cell |
| Fan 8212 J/2H4P | Thermal conditioning of the lithium-ion cell |

## How To Use

This repository consists of the main folder *implementation*, which itself contains three additional folders, *auxiliaries*, *model*, and *model_builds*.
The folder *auxiliaries* contains all files required for establishing a working CAN communication with the battery cycler (Python scripts to wrap a Matlab/Simulink C-code model and operate the embedded hardware, .cdf/.dll files defining the CAN protocol,
.sh files to configure the embedded hardware). The folder *model* contains a working version of a electrochemical model of reduced order and the use of this model in a Matlab/Simulink implementation. The folder *model_builds* contains the already
compiled Matlab/Simulink model to an executable file. For a step-by-step guide with the aforementioned hardware and software and more details, see the explanations as follows.

BaSyTec configuration:
1.  Connect CAN interface for battery cycler
2.  Insert OSI configuration file
      - Go to Extra / Define measurements and signals
      - Select channel by left-click on desired channel
      - Right-click on desired channel and select Add OSI
      - Open DLL-file from implementation/auxiliaries/cdf/DCFC_Test_Bench.dll
      - Adjust Prefix to a desired *TEST_BENCH_NR* (e.g., "1_")
      - Confirm and reboot BaSyTec software
      - Replace all occurences of "Device=" to the used CAN interface to cycler hardware number (e.g., "Device=HW345405" for our IXXAT USB-to-CAN compact interface)

Embedded hardware configuration:
1.	Flash the embedded hardware with the customized Linux OS image (e.g., with BalenaEtcher) via https://github.com/mathworks/Raspbian_OS_Setup/releases/download/R20.2.3/mathworks_raspbian_R20.2.3.zip 
2.  Boot the embedded hardware, connect it to the internet and log in with your credentials
3.  Clone the underlying repository by executing `git clone ea_battery_mdf https://github.com/TUMFTM/EA_Battery_MDF.git`
4.  Generate a Matlab/Simulink executable
      - Open the file *model/spmet_realtime.slx*
      - Adjust the model block as you desire.
      - Adjust building options in Matlab/Simulink via Configuration/Hardware implementation/Hardware board settings/Target hardware resources/Build options/Build directory and add the correct path `/home/pi/ea_battery_modeldeploymentframework/raspi_implementation/model_builds/[your elf file].elf`
      - Build standalone (ELF) in the *Hardware* tab and do not close the code generation report after completion for reference.
      - Adjust *NAME_OF_ELF* in *configuration.py*. For this, copy the name of the executable from the top of the build report and paste it in *configuration.py*.
5.  Modify the configuration file by executing `sudo nano /home/pi/ea_battery_mdf/implementation/auxiliaries/configuration.py`.
      - Change the *TEST_BENCH_NR* in code line 5 to a value between 1-6 if there are multiple MCUs connected to the same CAN-bus.
6.  Modify the embedded hardware configuration file by executing `sudo nano /home/pi/ea_battery_modeldeploymentframework/raspi_implementation/auxiliaries/pi.sh`.
      - Change the proxy *x* in *ssid=DCFC Test bench x* in line 43 to the number of the test bench you assigned in the last step.
7.  Run the automated configuration by executing `sudo bash /home/pi/ea_battery_modeldeploymentframework/raspi_implementation/auxiliaries/pi.sh`.
8.  Perform a reboot by executing "sudo reboot". The setup is now complete.
9.  Check setup by starting/stopping the main file.
      - "Start" - Restarts the main-file during runtime.
      - "Status" - Prints parameters to the terminal during runtime.
      - "Stop" - Stops the main-file during runtime.

## List of content

| File name | Function |
|---|---|
| auxiliaries/spmet.py | Call of Matlab/Simulink executable via STDIN/STDOUT |
| auxiliaries/pid.py | Discretized PID controller |
| auxiliaries/thermistor_readout_and_averaging.py | Evaluation of analog thermal sensors |
| auxiliaries/dcfc_test_bench.py | Main file with call routine of all submodules |
| auxiliaries/can_wrapper.py | CAN communication configuration and initialization |
| auxiliaries/can_definition_basytec.py | Battery cycler (BaSyTec) definitions (de)coding |
| auxiliaries/configuration.py | Configuration of MCU |
| model/spmet_realtime.slx | Matlab/Simulink environment for direct flashing of the lithium-ion battery model |


## Authors and Maintainers

- Nikolaos Wassiliadis, nikolaos.wassiliadis@tum.de
  - Idea, conceptualization and structure behind the project.
  - Supervision of the contributing student's theses.
  - Final revision and testing.

## Contributions

The authors want to thank the following persons, who, with their brilliant contributions made this work possible.

- Andreas Wiedemann, andreas.wiedemann@tum.de
  - Development of the framework and CAN communication functions as part of his master's thesis.
- Andreas Bach, andreas.bach@tum.de
  - Stability improvements as part of his master's thesis.
- Thomas Schöpfel, thomas.schoepfel@tum.de
  - Tuning of control properties as part of his master's studies.
- Jan Veeh, jan.veeh@tum.de
  - Deployment procedure and stability optimizations as part of his master's thesis.
