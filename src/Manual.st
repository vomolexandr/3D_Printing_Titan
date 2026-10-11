VAR
	TON0: TON;
	TON0_State: BOOL;
	TON1: TON;
	TON1_State: BOOL;
	TON2: TON;
	TON3: TON;
	TON4: TON;
	TON5: TON;
	TON2_State: BOOL;
	TON3_State: BOOL;
	TON4_State: BOOL;
	TON5_State: BOOL;
	TON_Freq: TON;
	HalfPeriod: TIME;
	HalfPeriod_time: TIME;
	TON_CMT1: TON;
	TON_CMT: TON;
	TON_CMT_State1: BOOL;
	TON_CMT_State: BOOL;
	Counter: INT;
	RTRIG_CMT: R_TRIG;
END_VAR

Y1 := MW0.8; Y2 := MW0.9; Y3 := MW0.10; Y4 := MW0.11; Y5 := MW0.12; Y6 := MW0.13; Y7 := MW0.14; Y8 := MW0.15; //Gases
//E-Magnet//
IF EmagFreqSet > 0 THEN EmagFreqCalc:= EmagFreqSet; ELSE EmagFreqCalc:= 10; END_IF //Обхід помилки ділення на нуль для прорахунку частоти ел.маг.
IF MW2.02 THEN
	EM_R_EN := TRUE;
	EM_L_EN := TRUE;
	HalfPeriod_us := REAL_TO_ULINT(1000000.0 / EmagFreqCalc / 2.0); //Період в мікросекундах
	SysTimeGetUs(CurrentTime); // CurrentTime ULINT
	IF (CurrentTime - LastToggleTime) >= HalfPeriod_us THEN //Перевірка пройденого часу
		ToggleState := NOT(ToggleState); //Інверсія
		LastToggleTime := CurrentTime; //Обнулення таймеру
	END_IF	
	EM_R_PWM := ToggleState;
	EM_L_PWM := NOT(ToggleState);
ELSE
	EM_R_EN := FALSE;
	EM_L_EN := FALSE;
	EM_R_PWM := FALSE;
	EM_L_PWM := FALSE;
	ToggleState := FALSE;
	LastToggleTime := 0;
END_IF
//E-Magnet//
PF1:= MW2.10; PF2:= MW2.11; PF3:= MW2.12; PF4:= MW2.13; //Powder feeders
PF1_SPD:= PF1_SPD_HMI_Man; PF2_SPD:= PF2_SPD_HMI_Man; PF3_SPD:= PF3_SPD_HMI_Man; PF4_SPD:= PF4_SPD_HMI_Man; //Powder feeders speed
//Wire feeders//
TON0(IN:= MW2.5, PT:= T#1MS, Q=> TON0_State); //Set1 dir1
TON1(IN:= NOT(MW2.5), PT:= T#1MS, Q=> TON1_State); //Set1 dir2
TON2(IN:= MW2.7, PT:= T#1MS, Q=> TON2_State); //Set2 dir1
TON3(IN:= NOT(MW2.7), PT:= T#1MS, Q=> TON3_State); //Set2 dir2
TON4(IN:= MW2.9, PT:= T#1MS, Q=> TON4_State); //Set3 dir1
TON5(IN:= NOT(MW2.9), PT:= T#1MS, Q=> TON5_State); //Set3 dir2
IF NOT(MW2.4) THEN MF1_CW:= FALSE; MF1_CCW:= FALSE; ELSE IF MW2.5 THEN MF1_CW:= FALSE; MF1_CCW:= TON0_State; ELSE MF1_CCW:= FALSE; MF1_CW:= TON1_State; END_IF END_IF //WF1
IF NOT(MW2.6) THEN MF2_CW:= FALSE; MF2_CCW:= FALSE; ELSE IF MW2.7 THEN MF2_CW:= FALSE; MF2_CCW:= TON2_State; ELSE MF2_CCW:= FALSE; MF2_CW:= TON3_State; END_IF END_IF //WF2
IF NOT(MW2.8) THEN MF3_CW:= FALSE; MF3_CCW:= FALSE; ELSE IF MW2.9 THEN MF3_CW:= FALSE; MF3_CCW:= TON4_State; ELSE MF3_CCW:= FALSE; MF3_CW:= TON5_State; END_IF END_IF //WF3
 //Wire feeders speed
//Wire feeders//
//PLASMA//
SetCurrent:= SetCurrent_HMI_Man; //Current set
IF NOT(MW0.7) THEN 
	StartParc:= MW2.0; 
	CMT_PS:= MW2.14; //CMT arc
	IF NOT(PilotArc) THEN IF NOT(MW2.1) THEN MW4.4 := TRUE; ELSE MW4.4 := FALSE; END_IF ELSE MW4.4 := FALSE; END_IF
	StartMArc:= MW2.1; //Main arc	
	MW4.2 := FALSE; MW4.6 := FALSE; 
END_IF//Pilot arc 

//PLASMA//
//CMT//
TON_CMT(IN:= CMT_PlusI OR CMT_MinusI, PT:= T#100MS, Q=> TON_CMT_State); //Таймер імпульсу для зміни значення
TON_CMT1(IN:= NOT(CMT_PlusI) AND NOT(CMT_MinusI), PT:= T#100MS, Q=> TON_CMT_State1); //Таймер паузи для зміни значення
IF SetCurrentCMT_HMI <> PrevCurrentCMT_HMI THEN Counter:= WORD_TO_INT(SetCurrentCMT_HMI) -  WORD_TO_INT(PrevCurrentCMT_HMI); //рахуємо кількість імпульсів
	IF Counter > 0 THEN  //Якщо потрібно збільшувати струм
		IF TON_CMT_State1 THEN CMT_PlusI:= TRUE; END_IF //Імпульс
		IF TON_CMT_State THEN CMT_PlusI:= FALSE; PrevCurrentCMT_HMI:= PrevCurrentCMT_HMI +1; Counter:= Counter -1; END_IF //Пауза + інкремент
	ELSIF Counter < 0 THEN  //Якщо потрібно зменшувати струм
		IF TON_CMT_State1 THEN CMT_MinusI:= TRUE; END_IF  //Імпульс
		IF TON_CMT_State THEN CMT_MinusI:= FALSE; PrevCurrentCMT_HMI:= PrevCurrentCMT_HMI -1; Counter:= Counter +1; END_IF //Пауза + декремент
	END_IF
	ELSE CMT_PlusI:= FALSE; CMT_MinusI:= FALSE; //Вимкнення інкрементального та декрементального реле по дефолту
END_IF
//CMT//


IF MW0.8 OR MW0.9 OR MW0.10 OR MW0.11 OR MW0.12 OR MW0.13 OR MW0.14 OR MW0.15 OR MW2.0 OR MW2.1 OR MW2.2 OR MW2.4 OR MW2.6 OR MW2.8 OR MW2.10 OR MW2.11 OR MW2.12 OR MW2.13 OR MW2.14 THEN
	MW6.14 := TRUE;
ELSE
	MW6.14 := FALSE;
END_IF

ProcON:= MW6.15; //Видача ProcON на робот
