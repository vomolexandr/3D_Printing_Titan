VAR_GLOBAL
	IX07 AT %IX0.7: BOOL;
	IW19 AT %IW19: WORD ;
	QW13 AT %QW13: WORD;
    Robot_MeasureCmd : BOOL; // 1 = міряти, 0 = зупинити
    Robot_MeasureCmd_Prev : BOOL := FALSE; // Попередній стан сигналу
    // Події
    StartEvent : BOOL := FALSE;
    StopEvent : BOOL := FALSE;
    // Стан вимірювання
    Measuring : BOOL := FALSE;
    MeasureDone : BOOL := FALSE;
    MeasureStatus : INT := 0;     // 0=idle, 1=measuring, 2=done, 3=error
    // Аналоговий сигнал
    VoltageRaw : REAL;
    VoltageFiltered : REAL;
    // Фільтрація
    K_Filter : REAL := 0.12;
    FirstSample : BOOL := TRUE;
    // Обмеження допустимого діапазону
    VoltageMin : REAL := 10.0;
    VoltageMax : REAL := 30.0;
    // Захист від різких викидів
    MaxJump : REAL := 10.0;
    SampleValid : BOOL := FALSE;
    // Накопичення середнього
    VoltageSum : REAL := 0.0;
    SampleCount : DINT := 0;
    VoltageAverage : REAL := 0.0;
    // Результат для Modbus
    VoltageAverage_x100 : WORD := 0;
	
	AVC_ON: BOOL;	
	AVC_Correction AT %QW13: UINT;
	PilotArcIN AT %IX0.0: BOOL;
	PilotArc: BOOL;
	MainArc AT %IX0.1: BOOL;
	//EncoderWF1 AT %IX0.4: BOOL;
	//EncoderWF2 AT %IX0.5: BOOL;
	//EncoderWF3 AT %IX0.6: BOOL;
	StartExt AT %IX1.0: BOOL;
	ReadyExt AT %IX1.1: BOOL;
	EmergencyExt AT %IX1.2: BOOL;
	
	EM_R_PWM AT %QX0.0: BOOL;
	EM_L_PWM AT %QX0.1: BOOL;
	EM_R_EN AT %QX0.2: BOOL;
	EM_L_EN AT %QX0.3: BOOL;
	StartParc AT %QX0.4: BOOL;
	StartMArc AT %QX0.5: BOOL;
	PArcON AT %QX0.6: BOOL;
	ProcON AT %QX0.7: BOOL;
	
	MF1_CW AT %QX3.0: BOOL;
	MF1_CCW AT %QX3.1: BOOL;
	MF2_CW AT %QX3.2: BOOL;
	MF2_CCW AT %QX3.3: BOOL;
	MF3_CW AT %QX3.4: BOOL;
	MF3_CCW AT %QX3.5: BOOL;
	
	Y1 AT %QX4.0: BOOL;
	Y2 AT %QX4.1: BOOL;
	Y3 AT %QX4.2: BOOL;
	Y4 AT %QX4.3: BOOL;
	Y5 AT %QX4.4: BOOL;
	Y6 AT %QX4.5: BOOL;
	Y7 AT %QX4.6: BOOL;
	Y8 AT %QX4.7: BOOL;
	
	PF1 AT %QX5.0: BOOL;
	PF2 AT %QX5.1: BOOL;
	PF3 AT %QX5.2: BOOL;
	PF4 AT %QX5.3: BOOL;
	
	CMT_PS AT %QX5.4: BOOL;
	CMT_PlusI AT %QX5.5: BOOL;
	CMT_MinusI AT %QX5.6: BOOL;
	
	PF1_SPD AT %QW3: WORD;
	PF2_SPD AT %QW4: WORD;
	PF3_SPD AT %QW5: WORD;
	PF4_SPD AT %QW6: WORD;
	
	WF1_SPD AT %QW7: WORD;
	WF2_SPD AT %QW8: WORD;
	WF3_SPD AT %QW9: WORD;
	
	SetCurrent AT %QW11: WORD;
	MeasureU AT %IW14: WORD;
	MeasureI AT %IW15: WORD;
	MeasureU_MHI AT %MW100: WORD;
	MeasureI_MHI AT %MW102: WORD;
	Alarms AT %MW104 : WORD;
	ErrorInManual AT %MW106: WORD;
	
	EmagFreqCalc: REAL;
	Toggle_Ready : BOOL;
	ToggleState : BOOL;
	LastToggleTime : ULINT := 0;
	CurrentTime : ULINT;
    HalfPeriod_us : ULINT;
	
	
	EmagFreqCalc_Auto: REAL;

	Freq_WF1 : REAL := 0.0;
	Freq_WF2 : REAL := 0.0;
	Freq_WF3 : REAL := 0.0;
	Correction : BOOL;
	
	Enable_Start : BOOL;
	
	TON_Delay_Start_PF : TON;
	TON_Delay_Start_WF : TON;
	TON_Delay_Start_Emagnet : TON;
	TON_preblow : TON;
	
	
	MW0 AT %MW0: WORD;
	MW2 AT %MW2: WORD;
	MW4 AT %MW4 : WORD;
	MW6 AT %MW6 : WORD;
	MW8 AT %MW8 : WORD;
	PrevCurrentCMT_HMI : WORD;
END_VAR

VAR_GLOBAL RETAIN	
	EmagFreqSet AT %MD11: REAL;
	
	AVC_Voltage AT %MW12: WORD;
	AVC_Accuracy AT %MW14: WORD;
	AVC_PID_Kp AT %MD8: REAL;
	AVC_PID_Ki AT %MD55: REAL;
	AVC_DELAY AT %MW114: WORD;
	
	SetCurrent_HMI_Man AT %MW20: WORD;
	WF1_SPD_HMI_Man AT %MW26: WORD;
	WF2_SPD_HMI_Man AT %MW28: WORD;
	WF3_SPD_HMI_Man AT %MW30: WORD;
	PF1_SPD_HMI_Man AT %MW32: WORD;
	PF2_SPD_HMI_Man AT %MW34: WORD;
	PF3_SPD_HMI_Man AT %MW36: WORD;
	PF4_SPD_HMI_Man AT %MW38: WORD;
	SetCurrentCMT_HMI AT %MW40: WORD;
	Check_Voltage_Current_Delay AT %MW42 : WORD;
	Emergency_Delay AT %MW44 : WORD;
	Auto_Button_State AT %MW46 : WORD;
	Set_Emergency_Voltage AT %MW48 : WORD;
	Set_Emergency_Current AT %MW50 : WORD;
	
	EmagFreqSet_Auto AT %MD27: REAL;
	SetCurrent_HMI_Auto AT %MW52: WORD;
	WF1_SPD_HMI_Auto AT %MW58: WORD;
	WF2_SPD_HMI_Auto AT %MW60: WORD;
	WF3_SPD_HMI_Auto AT %MW62: WORD;
	PF1_SPD_HMI_Auto AT %MW64: WORD;
	PF2_SPD_HMI_Auto AT %MW66: WORD;
	PF3_SPD_HMI_Auto AT %MW68: WORD;
	PF4_SPD_HMI_Auto AT %MW70: WORD;
	Delay_Gas_Preblow AT %MW74 : WORD;
 	Delay_Gas_Finishblow AT %MW76 : WORD;
	Delay_Gas_Analysys AT %MW78 : WORD;
	Process_Auto AT %MW80 : WORD;
	Delay_Start_PF AT %MW82 : WORD;
	Delay_Start_WF AT %MW84 : WORD;
	Delay_Start_Emagnet AT %MW86 : WORD;
	Delay_Stop_PF AT %MW88 : WORD;
	Delay_Stop_WF AT %MW90 : WORD;
	Delay_Stop_Emagnet AT %MW92 : WORD;
	Delay_Analysys_Pilot AT %MW94 : WORD;
	Delay_Analysys_Main AT %MW96 : WORD;  
END_VAR
