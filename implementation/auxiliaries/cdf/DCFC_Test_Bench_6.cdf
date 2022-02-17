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
ID=1537
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
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_1]
Name=fan_pwm
MSGID=1537
MSGNR=1
ANSID=-1
Start=0
Factor=1
Offset=0
Datapos=181
Linear=1
Unit=%
DataName=
Dataformat=UI8
Endian=Little
[SIG_2]
Name=fan_rpm
MSGID=1537
MSGNR=1
ANSID=-1
Start=8
Factor=1
Offset=0
Datapos=182
Linear=1
Unit=RPM
DataName=
Dataformat=I16
Endian=Little
[SIG_3]
Name=controller_p
MSGID=1537
MSGNR=1
ANSID=-1
Start=24
Factor=1
Offset=0
Datapos=183
Linear=1
Unit=
DataName=
Dataformat=I8
Endian=Little
[SIG_4]
Name=controller_i
MSGID=1537
MSGNR=1
ANSID=-1
Start=32
Factor=1
Offset=0
Datapos=184
Linear=1
Unit=
DataName=
Dataformat=I8
Endian=Little
[SIG_5]
Name=controller_d
MSGID=1537
MSGNR=1
ANSID=-1
Start=40
Factor=1
Offset=0
Datapos=28
Linear=1
Unit=
DataName=
Dataformat=I8
Endian=Little
[MSG_2]
ID=1538
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
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_6]
Name=t_a
MSGID=1538
MSGNR=2
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=29
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_7]
Name=t_b
MSGID=1538
MSGNR=2
ANSID=-1
Start=16
Factor=0.01
Offset=0
Datapos=30
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_8]
Name=t_c
MSGID=1538
MSGNR=2
ANSID=-1
Start=32
Factor=0.01
Offset=0
Datapos=31
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_9]
Name=t_status
MSGID=1538
MSGNR=2
ANSID=-1
Start=48
Factor=1
Offset=0
Datapos=32
Linear=1
Unit=bin
DataName=
Dataformat=UI8
Endian=Little
[MSG_3]
ID=1539
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
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_10]
Name=voltage_sim
MSGID=1539
MSGNR=3
ANSID=-1
Start=0
Factor=0.0001
Offset=0
Datapos=33
Linear=1
Unit=V
DataName=
Dataformat=UI16
Endian=Little
[SIG_11]
Name=soc_sim
MSGID=1539
MSGNR=3
ANSID=-1
Start=16
Factor=0.4
Offset=0
Datapos=191
Linear=1
Unit=%
DataName=
Dataformat=UI8
Endian=Little
[SIG_12]
Name=temp_core_sim
MSGID=1539
MSGNR=3
ANSID=-1
Start=24
Factor=0.01
Offset=0
Datapos=34
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[SIG_13]
Name=t_solve
MSGID=1539
MSGNR=3
ANSID=-1
Start=40
Factor=0.001
Offset=0
Datapos=193
Linear=1
Unit=s
DataName=
Dataformat=UI8
Endian=Little
[SIG_14]
Name=set_current_sim
MSGID=1539
MSGNR=3
ANSID=-1
Start=48
Factor=0.001
Offset=0
Datapos=194
Linear=1
Unit=
DataName=
Dataformat=I16
Endian=Little
[MSG_4]
ID=1540
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
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_15]
Name=pot_n
MSGID=1540
MSGNR=4
ANSID=-1
Start=0
Factor=0.0001
Offset=0
Datapos=195
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_16]
Name=eta_n
MSGID=1540
MSGNR=4
ANSID=-1
Start=16
Factor=0.0001
Offset=0
Datapos=196
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_17]
Name=eta_sei_n
MSGID=1540
MSGNR=4
ANSID=-1
Start=32
Factor=0.001
Offset=0
Datapos=197
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_18]
Name=delta_c_n_max
MSGID=1540
MSGNR=4
ANSID=-1
Start=48
Factor=1000000
Offset=0
Datapos=198
Linear=1
Unit=E6
DataName=
Dataformat=UI16
Endian=Little
[MSG_5]
ID=1541
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
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_19]
Name=pot_p
MSGID=1541
MSGNR=5
ANSID=-1
Start=0
Factor=0.001
Offset=0
Datapos=199
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_20]
Name=eta_p
MSGID=1541
MSGNR=5
ANSID=-1
Start=16
Factor=0.001
Offset=0
Datapos=200
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_21]
Name=eta_sei_p
MSGID=1541
MSGNR=5
ANSID=-1
Start=32
Factor=0.001
Offset=0
Datapos=201
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_22]
Name=delta_c_p_max
MSGID=1541
MSGNR=5
ANSID=-1
Start=48
Factor=1000000
Offset=0
Datapos=202
Linear=1
Unit=E6
DataName=
Dataformat=UI16
Endian=Little
[MSG_6]
ID=1546
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
MSGID=1546
MSGNR=6
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=203
Linear=1
Unit=%
DataName=
Dataformat=UI16
Endian=Little
[SIG_24]
Name=actual_current
MSGID=1546
MSGNR=6
ANSID=-1
Start=16
Factor=0.001
Offset=0
Datapos=204
Linear=1
Unit=A
DataName=
Dataformat=I16
Endian=Little
[SIG_25]
Name=actual_voltage
MSGID=1546
MSGNR=6
ANSID=-1
Start=32
Factor=0.0001
Offset=0
Datapos=205
Linear=1
Unit=V
DataName=
Dataformat=UI16
Endian=Little
[MSG_7]
ID=1547
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
MSGID=1547
MSGNR=7
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=206
Linear=1
Unit=%
DataName=
Dataformat=UI16
Endian=Little
[SIG_27]
Name=init_capacity
MSGID=1547
MSGNR=7
ANSID=-1
Start=16
Factor=0.0001
Offset=0
Datapos=207
Linear=1
Unit=Ah
DataName=
Dataformat=I16
Endian=Little
[SIG_28]
Name=init_sei_r
MSGID=1547
MSGNR=7
ANSID=-1
Start=32
Factor=1E-5
Offset=0
Datapos=208
Linear=1
Unit=Ohm*m2
DataName=
Dataformat=UI16
Endian=Little
[SIG_29]
Name=init_temp_core
MSGID=1547
MSGNR=7
ANSID=-1
Start=48
Factor=0.01
Offset=0
Datapos=209
Linear=1
Unit=C
DataName=
Dataformat=I16
Endian=Little
[MSG_8]
ID=1548
ID_TX=0
MSGNR=8
Active=1
Filter=0
FilterByte=1
FilterData=8
Filter2=0
FilterByte2=1
FilterData2=8
Name=Control from BaSyTec
Datalength=8
Datadir=TXD
TxPeriod=20
TxData=AAAAAAAAAAAAAAAA
[SIG_30]
Name=max_current
MSGID=1548
MSGNR=8
ANSID=-1
Start=0
Factor=0.01
Offset=0
Datapos=210
Linear=1
Unit=A
DataName=
Dataformat=I16
Endian=Little
[SIG_31]
Name=max_voltage
MSGID=1548
MSGNR=8
ANSID=-1
Start=16
Factor=0.02
Offset=0
Datapos=211
Linear=1
Unit=V
DataName=
Dataformat=UI8
Endian=Little
[SIG_32]
Name=max_temp_core
MSGID=1548
MSGNR=8
ANSID=-1
Start=24
Factor=1
Offset=0
Datapos=212
Linear=1
Unit=C
DataName=
Dataformat=I8
Endian=Little
[SIG_33]
Name=min_pot_n
MSGID=1548
MSGNR=8
ANSID=-1
Start=32
Factor=0.0001
Offset=0
Datapos=213
Linear=1
Unit=V
DataName=
Dataformat=I16
Endian=Little
[SIG_34]
Name=start_simulation
MSGID=1548
MSGNR=8
ANSID=-1
Start=48
Factor=1
Offset=0
Datapos=214
Linear=1
Unit=bin
DataName=
Dataformat=I8
Endian=Little
[SIG_35]
Name=set_temp_fan
MSGID=1548
MSGNR=8
ANSID=-1
Start=56
Factor=1
Offset=0
Datapos=215
Linear=1
Unit=C
DataName=
Dataformat=I8
Endian=Little