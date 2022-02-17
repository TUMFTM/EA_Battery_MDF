[General]
Version=2600
Canversion=2.0A
Baudrate=250
BTR0=1
BTR1=28
Device=HW345405
SendAck=1
RecSelf=0
IgnoreBusError=1
DefaultValue=0
CanState=CanState
TxDelay=0
[MSG_1]
ID=1025
ID_TX=0
MSGNR=1
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Fan Controller to BaSyTec
Datalength=8
Datadir=RXD
TxPeriod=1000
TxData=AAAAAAAAAAAAAAAA
[SIG_1]
Name=fan_pwm
MSGID=1025
MSGNR=1
ANSID=-1
Start=0
Factor=1
Offset=0
Datapos=110
Linear=1
Unit=%
DataName=
Dataformat=UI8
Endian=Little
[SIG_2]
Name=fan_rpm
MSGID=1025
MSGNR=1
ANSID=-1
Start=8
Factor=1
Offset=0
Datapos=111
Linear=1
Unit=RPM
DataName=
Dataformat=I16
Endian=Little
[SIG_3]
Name=controller_p
MSGID=1025
MSGNR=1
ANSID=-1
Start=24
Factor=1
Offset=0
Datapos=112
Linear=1
Unit=
DataName=
Dataformat=I8
Endian=Little
[SIG_4]
Name=controller_i
MSGID=1025
MSGNR=1
ANSID=-1
Start=32
Factor=1
Offset=0
Datapos=113
Linear=1
Unit=
DataName=
Dataformat=I8
Endian=Little
[SIG_5]
Name=controller_d
MSGID=1025
MSGNR=1
ANSID=-1
Start=40
Factor=1
Offset=0
Datapos=114
Linear=1
Unit=
DataName=
Dataformat=I8
Endian=Little
[MSG_2]
ID=1026
ID_TX=0
MSGNR=2
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Temps to BaSyTec
Datalength=8
Datadir=RXD
TxPeriod=1000
TxData=AAAAAAAAAAAAAAAA
[SIG_6]
Name=t_a
MSGID=1026
MSGNR=2
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=115
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_7]
Name=t_b
MSGID=1026
MSGNR=2
ANSID=-1
Start=16
Factor=0.01
Offset=0
Datapos=116
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_8]
Name=t_c
MSGID=1026
MSGNR=2
ANSID=-1
Start=32
Factor=0.01
Offset=0
Datapos=117
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_9]
Name=t_status
MSGID=1026
MSGNR=2
ANSID=-1
Start=48
Factor=1
Offset=0
Datapos=118
Linear=1
Unit=bin
DataName=
Dataformat=UI8
Endian=Little
[MSG_3]
ID=1027
ID_TX=0
MSGNR=3
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Sim to BaSyTec
Datalength=8
Datadir=RXD
TxPeriod=1000
TxData=AAAAAAAAAAAAAAAA
[SIG_10]
Name=voltage_sim
MSGID=1027
MSGNR=3
ANSID=-1
Start=0
Factor=0.0001
Offset=0
Datapos=119
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_11]
Name=soc_sim
MSGID=1027
MSGNR=3
ANSID=-1
Start=16
Factor=0.4
Offset=0
Datapos=120
Linear=1
Unit=%
DataName=
Dataformat=UI8
Endian=Little
[SIG_12]
Name=temp_core_sim
MSGID=1027
MSGNR=3
ANSID=-1
Start=24
Factor=0.01
Offset=0
Datapos=121
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_13]
Name=t_solve
MSGID=1027
MSGNR=3
ANSID=-1
Start=40
Factor=0.001
Offset=0
Datapos=122
Linear=1
Unit=s
DataName=
Dataformat=UI8
Endian=Little
[SIG_14]
Name=set_current_sim
MSGID=1027
MSGNR=3
ANSID=-1
Start=48
Factor=0.001
Offset=0
Datapos=123
Linear=1
Unit=
DataName=
Dataformat=I16
Endian=Little
[MSG_4]
ID=1028
ID_TX=0
MSGNR=4
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Sim to BaSyTec (Anode)
Datalength=8
Datadir=RXD
TxPeriod=1000
TxData=AAAAAAAAAAAAAAAA
[SIG_15]
Name=pot_n
MSGID=1028
MSGNR=4
ANSID=-1
Start=0
Factor=0.0001
Offset=0
Datapos=124
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_16]
Name=eta_n
MSGID=1028
MSGNR=4
ANSID=-1
Start=16
Factor=0.0001
Offset=0
Datapos=125
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_17]
Name=eta_sei_n
MSGID=1028
MSGNR=4
ANSID=-1
Start=32
Factor=0.001
Offset=0
Datapos=126
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_18]
Name=delta_c_n_max
MSGID=1028
MSGNR=4
ANSID=-1
Start=48
Factor=1000000
Offset=0
Datapos=127
Linear=1
Unit=E6
DataName=
Dataformat=UI16
Endian=Little
[MSG_5]
ID=1029
ID_TX=0
MSGNR=5
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Sim to BaSyTec (Kathode)
Datalength=8
Datadir=RXD
TxPeriod=1000
TxData=AAAAAAAAAAAAAAAA
[SIG_19]
Name=pot_p
MSGID=1029
MSGNR=5
ANSID=-1
Start=0
Factor=0.001
Offset=0
Datapos=128
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_20]
Name=eta_p
MSGID=1029
MSGNR=5
ANSID=-1
Start=16
Factor=0.001
Offset=0
Datapos=129
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_21]
Name=eta_sei_p
MSGID=1029
MSGNR=5
ANSID=-1
Start=32
Factor=0.001
Offset=0
Datapos=130
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_22]
Name=delta_c_p_max
MSGID=1029
MSGNR=5
ANSID=-1
Start=48
Factor=1000000
Offset=0
Datapos=131
Linear=1
Unit=E6
DataName=
Dataformat=UI16
Endian=Little
[MSG_6]
ID=1034
ID_TX=0
MSGNR=6
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Values from BaSyTec
Datalength=8
Datadir=TXD
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_23]
Name=actual_soc
MSGID=1034
MSGNR=6
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=132
Linear=1
Unit=%
DataName=
Dataformat=UI16
Endian=Little
[SIG_24]
Name=actual_current
MSGID=1034
MSGNR=6
ANSID=-1
Start=16
Factor=0.001
Offset=0
Datapos=133
Linear=1
Unit=A
DataName=
Dataformat=I16
Endian=Little
[SIG_25]
Name=actual_voltage
MSGID=1034
MSGNR=6
ANSID=-1
Start=32
Factor=0.0001
Offset=0
Datapos=134
Linear=1
Unit=V
DataName=
Dataformat=UI16
Endian=Little
[MSG_7]
ID=1035
ID_TX=0
MSGNR=7
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Init Values from BaSyTec
Datalength=8
Datadir=TXD
TxPeriod=1000
TxData=AAAAAAAAAAAAAAAA
[SIG_26]
Name=init_soc
MSGID=1035
MSGNR=7
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=135
Linear=1
Unit=%
DataName=
Dataformat=UI16
Endian=Little
[SIG_27]
Name=init_capacity
MSGID=1035
MSGNR=7
ANSID=-1
Start=16
Factor=0.0001
Offset=0
Datapos=136
Linear=1
Unit=Ah
DataName=
Dataformat=UI16
Endian=Little
[SIG_28]
Name=init_sei_r
MSGID=1035
MSGNR=7
ANSID=-1
Start=32
Factor=1E-5
Offset=0
Datapos=137
Linear=1
Unit=Ohm*m2
DataName=
Dataformat=UI16
Endian=Little
[SIG_29]
Name=init_temp_core
MSGID=1035
MSGNR=7
ANSID=-1
Start=48
Factor=0.01
Offset=0
Datapos=138
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[MSG_8]
ID=1036
ID_TX=0
MSGNR=8
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Fan Control from BaSyTec
Datalength=8
Datadir=TXD
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_30]
Name=max_current
MSGID=1036
MSGNR=8
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=139
Linear=1
Unit=A
DataName=
Dataformat=I16
Endian=Little
[SIG_31]
Name=max_voltage
MSGID=1036
MSGNR=8
ANSID=-1
Start=16
Factor=0.02
Offset=0
Datapos=140
Linear=1
Unit=V
DataName=
Dataformat=UI8
Endian=Little
[SIG_32]
Name=max_temp_core
MSGID=1036
MSGNR=8
ANSID=-1
Start=24
Factor=1
Offset=0
Datapos=141
Linear=1
Unit=C
DataName=
Dataformat=I8
Endian=Little
[SIG_33]
Name=min_pot_n
MSGID=1036
MSGNR=8
ANSID=-1
Start=32
Factor=0.0001
Offset=0
Datapos=142
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_34]
Name=start_simulation
MSGID=1036
MSGNR=8
ANSID=-1
Start=48
Factor=1
Offset=0
Datapos=143
Linear=1
Unit=bin
DataName=
Dataformat=I8
Endian=Little
[SIG_35]
Name=set_temp_fan
MSGID=1036
MSGNR=8
ANSID=-1
Start=56
Factor=1
Offset=0
Datapos=144
Linear=1
Unit=C
DataName=
Dataformat=I8
Endian=Little
