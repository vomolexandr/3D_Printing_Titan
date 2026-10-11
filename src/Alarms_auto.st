VAR
	TON0: TON;
	TON1: TON;
	TON_Analysys_Pilot: TON;
	TON_Analysys_Main: TON;
	TON_Delay_Stop_PF: TON;
	TON_Delay_Stop_WF: TON;
	TON_Delay_Stop_Emagnet: TON;
	TON_Finish_blow: TON;
	Allow_finish_blow: BOOL;
	Prev_Process: WORD;
	T: BOOL;
	TRIG_MW6_9: BOOL;
END_VAR

TON0(IN:= (Process_Auto = 3 AND Alarms = 0), PT:= WORD_TO_TIME(Check_Voltage_Current_Delay)); //Затримка аналізу Voltage та Current
TON_Analysys_Pilot(IN:= StartParc, PT:= WORD_TO_TIME(Delay_Analysys_Pilot*10));//Затримка аналізу чергової дуги
TON_Analysys_Main(IN:= StartMArc, PT:= WORD_TO_TIME(Delay_Analysys_Main*10));//Затримка аналізу основної дуги

//Аналіз чергової та основної дуги
IF TON_Analysys_Pilot.Q AND NOT(PilotArc) AND Auto_Button_State = 1 THEN MW6.10 := TRUE; IF Alarms = 0 THEN Alarms := 4; END_IF END_IF
IF TON_Analysys_Main.Q AND NOT(MainArc) AND Auto_Button_State = 1 THEN MW6.10 := TRUE; IF Alarms = 0 THEN Alarms := 5; END_IF END_IF

//Check Voltage and Current
IF TON0.Q THEN
	IF Set_Emergency_Voltage > MeasureU AND MW4.0 AND MW4.15 THEN MW6.10 := TRUE; IF Alarms = 0 THEN Alarms := 1; END_IF END_IF
	IF Set_Emergency_Current > MeasureI AND MW4.1 AND MW4.15 THEN MW6.10 := TRUE; IF Alarms = 0 THEN Alarms := 2; END_IF END_IF
END_IF

// Ввікнення аварії при нажатій кнопці Emergency stop
IF NOT(EmergencyExt) AND Process_Auto <> 0 AND Auto_Button_State <> 0 THEN IF Alarms = 0 THEN Alarms := 3;  END_IF  END_IF

//Ready total
IF MW6.0 OR MW4.15 THEN
	IF ((((Auto_Button_State = 1 OR Auto_Button_State = 2) AND (Y1 OR Y2 OR Y3 OR Y4)) OR (Auto_Button_State = 0 AND (MW6.1 OR MW6.2 OR MW6.3 OR MW6.4))) AND 
	EmergencyExt AND NOT(MW6.10) AND Alarms = 0) THEN 
		IF NOT(MW4.3) THEN
			MW6.11 := TRUE;
			//MW0.2
		ELSIF MW4.3 AND MW0.2 THEN
			MW6.11 := TRUE;
		ELSE 
			MW6.11 := FALSE; 
		END_IF
	ELSE 
		MW6.11 := FALSE; 
	END_IF
ELSE
	MW6.11 := FALSE;
END_IF

//Robot not ready
IF MW4.3 AND Auto_Button_State = 1 AND NOT(MW0.2) THEN MW6.10 := TRUE; IF Alarms = 0 THEN Alarms := 6; END_IF END_IF

TON1(IN:= MW6.10, PT:= WORD_TO_TIME(Emergency_Delay)); //Затримка аварійного вимкнення

//Аварійна зупинка
IF (TON1.Q OR Auto_Button_State = 2) AND EmergencyExt THEN
	//YES
	MW6.12 := FALSE;
	
	//Block start
	MW6.6 := TRUE;
	
	//Set stop to button
	IF Auto_Button_State <> 0 THEN Auto_Button_State := 2; END_IF
	
	//Save stop process
	IF Process_Auto <> 6 AND Process_Auto <> 4 THEN Prev_Process := Process_Auto; END_IF
	
	//Pre-blowing
	IF Prev_Process = 1 THEN
		Allow_finish_blow := TRUE;
		
	//Waiting Pilot Arc
	ELSIF Prev_Process = 2 THEN
		//Turn off Pilot Arc
		StartParc:= FALSE;
		Allow_finish_blow := TRUE;
		
	//Working Process and CMT Start
	ELSIF Prev_Process = 3 THEN
		// CMT OFF
		CMT_PS := FALSE;
		CMT_PlusI:= FALSE; CMT_MinusI:= FALSE;
		//Turn off Main Arc
		StartMArc:= FALSE;	
		//Turn off Pilot Arc
		StartParc:= FALSE;
		TON_Delay_Stop_PF(IN:=TON_Delay_Start_PF.Q, PT:=WORD_TO_TIME(Delay_Stop_PF));
		TON_Delay_Stop_WF(IN:=TON_Delay_Start_WF.Q, PT:=WORD_TO_TIME(Delay_Stop_WF));
		TON_Delay_Stop_Emagnet(IN:=TON_Delay_Start_Emagnet.Q, PT:=WORD_TO_TIME(Delay_Stop_Emagnet));
		IF (
			(NOT(MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) OR (((MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) AND NOT(TON_Delay_Start_PF.Q)) OR TON_Delay_Stop_PF.Q)) AND
			(NOT(MW4.12 OR MW4.13 OR MW4.14) OR (((MW4.12 OR MW4.13 OR MW4.14) AND NOT(TON_Delay_Start_WF.Q)) OR TON_Delay_Stop_WF.Q))AND
			(NOT(MW4.11) OR ((MW4.11 AND NOT(TON_Delay_Start_Emagnet.Q)) OR TON_Delay_Stop_Emagnet.Q)) 
			) THEN
				Allow_finish_blow := TRUE;
		ELSE
			Process_Auto := 6;
		END_IF
		
	//Waiting Main Arc
	ELSIF Prev_Process = 8 THEN
		//Turn off Main Arc
		StartMArc:= FALSE;
		//Turn off Pilot Arc
		StartParc:= FALSE;
		Allow_finish_blow := TRUE;
		
	//Waiting Additional equipment
	ELSIF Prev_Process = 9 THEN
		// CMT OFF
		CMT_PS := FALSE;
		CMT_PlusI:= FALSE; CMT_MinusI:= FALSE;
		//Turn off Main Arc
		StartMArc:= FALSE;	
		//Turn off Pilot Arc
		StartParc:= FALSE;
		TON_Delay_Stop_PF(IN:=TON_Delay_Start_PF.Q, PT:=WORD_TO_TIME(Delay_Stop_PF));
		TON_Delay_Stop_WF(IN:=TON_Delay_Start_WF.Q, PT:=WORD_TO_TIME(Delay_Stop_WF));
		TON_Delay_Stop_Emagnet(IN:=TON_Delay_Start_Emagnet.Q, PT:=WORD_TO_TIME(Delay_Stop_Emagnet));
		IF (
			(NOT(MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) OR (((MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) AND NOT(TON_Delay_Start_PF.Q)) OR TON_Delay_Stop_PF.Q)) AND
			(NOT(MW4.12 OR MW4.13 OR MW4.14) OR (((MW4.12 OR MW4.13 OR MW4.14) AND NOT(TON_Delay_Start_WF.Q)) OR TON_Delay_Stop_WF.Q)) AND
			(NOT(MW4.11) OR ((MW4.11 AND NOT(TON_Delay_Start_Emagnet.Q)) OR TON_Delay_Stop_Emagnet.Q))
			) THEN
				Allow_finish_blow := TRUE;
		ELSE
			Process_Auto := 6;
		END_IF
	END_IF
	IF TON_Delay_Stop_PF.Q THEN PF1 := FALSE; PF2 := FALSE; PF3 := FALSE; PF4 := FALSE; Y5 := FALSE; Y6 := FALSE; Y7 := FALSE; Y8 := FALSE; END_IF
	IF TON_Delay_Stop_WF.Q THEN MF1_CW:= FALSE; MF1_CCW := FALSE; MF2_CW:= FALSE; MF2_CCW := FALSE; MF3_CW:= FALSE; MF3_CCW := FALSE; END_IF
	IF (MW4.11 AND NOT(TON_Delay_Start_Emagnet.Q)) OR TON_Delay_Stop_Emagnet.Q OR Allow_finish_blow THEN 
		//Вимикаємо магніт
		EM_R_EN := FALSE;
		EM_L_EN := FALSE;
		EM_R_PWM := FALSE;
		EM_L_PWM := FALSE;
		ToggleState := FALSE;
		LastToggleTime := 0;
	ELSIF Prev_Process <> 1 AND Prev_Process <> 2 AND Prev_Process <> 8 AND Auto_Button_State <> 0 AND Prev_Process <> 0 THEN
		IF MW4.11 THEN
				EM_R_EN := TRUE;
				EM_L_EN := TRUE;
				HalfPeriod_us := REAL_TO_ULINT(1000000.0 / EmagFreqCalc_Auto / 2.0); //Період в мікросекундах
				SysTimeGetUs(CurrentTime); // CurrentTime ULINT
				IF (CurrentTime - LastToggleTime) >= HalfPeriod_us THEN //Перевірка пройденого часу
					ToggleState := NOT(ToggleState); //Інверсія
					LastToggleTime := CurrentTime; //Обнулення таймеру
				END_IF	
				EM_R_PWM := ToggleState;
				EM_L_PWM := NOT(ToggleState);
		END_IF
	END_IF
	//Finish blowing
	IF Allow_finish_blow THEN
				TON_Finish_blow(IN:=Enable_Start, PT:=WORD_TO_TIME(Delay_Gas_Finishblow * 10));
				//Finish blow
				IF TON_Finish_blow.Q THEN Allow_finish_blow := FALSE; Y1 := FALSE; Y2 := FALSE; Y3 := FALSE; Y4 := FALSE; Enable_Start := FALSE; Process_Auto := 0; 
				TON_Delay_Stop_PF(IN:=FALSE); TON_Delay_Stop_Emagnet(IN:=FALSE); TON_Delay_Stop_WF(IN:=FALSE); TON_Finish_blow(IN:=FALSE);
				TON_Delay_Start_PF(IN:=FALSE); TON_Delay_Start_Emagnet(IN:=FALSE); TON_Delay_Start_WF(IN:=FALSE);TON_preblow(IN:=FALSE);
				MW6.13 := FALSE;
				Auto_Button_State := 0;
				Prev_Process := 0;
				ELSE Process_Auto := 4; END_IF
				
	END_IF
ELSIF NOT(TON1.Q) AND MW6.10 THEN
	IF MW4.11 THEN
				EM_R_EN := TRUE;
				EM_L_EN := TRUE;
				HalfPeriod_us := REAL_TO_ULINT(1000000.0 / EmagFreqCalc_Auto / 2.0); //Період в мікросекундах
				SysTimeGetUs(CurrentTime); // CurrentTime ULINT
				IF (CurrentTime - LastToggleTime) >= HalfPeriod_us THEN //Перевірка пройденого часу
					ToggleState := NOT(ToggleState); //Інверсія
					LastToggleTime := CurrentTime; //Обнулення таймеру
				END_IF	
				EM_R_PWM := ToggleState;
				EM_L_PWM := NOT(ToggleState);
	END_IF
END_IF

//Emergency Stop
IF (NOT(EmergencyExt) OR (Process_Auto = 4 OR Process_Auto = 6)) AND Auto_Button_State <> 0 AND NOT(MW6.11) AND Alarms = 3 THEN
	//YES
	MW6.12 := FALSE;
	
	//Block start
	MW6.6 := TRUE;
	
	//Set stop to button
	IF Auto_Button_State <> 0 THEN Auto_Button_State := 2; END_IF
	
	// CMT OFF
	CMT_PS := FALSE;
	CMT_PlusI:= FALSE; CMT_MinusI:= FALSE;
	
	//Turn off Main Arc
	StartMArc:= FALSE;	
	
	//Turn off Pilot Arc
	StartParc:= FALSE;
	
	//Вимикаємо магніт
	EM_R_EN := FALSE;
	EM_L_EN := FALSE;
	EM_R_PWM := FALSE;
	EM_L_PWM := FALSE;
	ToggleState := FALSE;
	LastToggleTime := 0;
	PF1 := FALSE; PF2 := FALSE; PF3 := FALSE; PF4 := FALSE; Y5 := FALSE; Y6 := FALSE; Y7 := FALSE; Y8 := FALSE;
	MF1_CW:= FALSE; MF1_CCW := FALSE; MF2_CW:= FALSE; MF2_CCW := FALSE; MF3_CW:= FALSE; MF3_CCW := FALSE;
	
	//Finish blow
	TON_Finish_blow(IN:=Enable_Start, PT:=WORD_TO_TIME(Delay_Gas_Finishblow * 10));
	IF TON_Finish_blow.Q THEN Allow_finish_blow := FALSE; Y1 := FALSE; Y2 := FALSE; Y3 := FALSE; Y4 := FALSE; Enable_Start := FALSE; Process_Auto := 0; 
		TON_Delay_Stop_PF(IN:=FALSE); TON_Delay_Stop_Emagnet(IN:=FALSE); TON_Delay_Stop_WF(IN:=FALSE); TON_Finish_blow(IN:=FALSE);
		TON_Delay_Start_PF(IN:=FALSE); TON_Delay_Start_Emagnet(IN:=FALSE); TON_Delay_Start_WF(IN:=FALSE);TON_preblow(IN:=FALSE);
		MW6.13 := FALSE;
		Auto_Button_State := 0;
		Prev_Process := 0;
	ELSE Process_Auto := 4; END_IF
END_IF

//Reset Alarm
IF MW4.5 AND Auto_Button_State <> 2 THEN Alarms := 0; MW6.10 := FALSE; MW6.13 := FALSE; MW6.9 := FALSE; MW6.5:= FALSE;  TON_Finish_blow(IN:=FALSE); END_IF //Скидання аларму
