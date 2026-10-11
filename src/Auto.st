VAR
	TON_After_Stop: TON;
	TON_After_Stop_state: BOOL;
	TON_Finish_blow: TON;
	TON_Finish_blow_state: BOOL;
	TON_CMT: TON;
	TON_CMT_State: BOOL;
	TON_CMT1: TON;
	TON_CMT_State1: BOOL;
	Counter: INT;
	R_TRIG_state: BOOL;
	Prev_MW4_15: BOOL;
	Prev_MW6_0: BOOL;
	TON_Delay_Stop_PF: TON;
	TON_Delay_Stop_WF: TON;
	TON_Delay_Stop_Emagnet: TON;
	R_TRIG_External: R_TRIG;
	TON_Alarm: TON;
	TON_Alarm2: TON;
	Step: BOOL;
	Allow_finish_blow: BOOL;
	Prev_Process: WORD;
END_VAR

// Встановлення Powder Feeder
IF MW4.7 THEN PF1_SPD := PF1_SPD_HMI_Auto; END_IF
IF MW4.8 THEN PF2_SPD := PF2_SPD_HMI_Auto; END_IF
IF MW4.9 THEN PF3_SPD := PF3_SPD_HMI_Auto; END_IF
IF MW4.10 THEN PF4_SPD := PF4_SPD_HMI_Auto; END_IF

// E-magnet
IF MW4.11 THEN 
	IF EmagFreqSet_Auto > 0 THEN EmagFreqCalc_Auto:= EmagFreqSet_Auto; ELSE EmagFreqCalc_Auto:= 10; END_IF //Обхід помилки ділення на нуль для прорахунку частоти ел.маг.
END_IF

// Встановлення Wire Feeder
IF MW4.12 THEN WF1_SPD := WF1_SPD_HMI_Auto; END_IF
IF MW4.13 THEN WF2_SPD := WF2_SPD_HMI_Auto; END_IF
IF MW4.14 THEN WF3_SPD := WF3_SPD_HMI_Auto; END_IF


// Ввімкнення іншого режиму
IF MW6.0 AND NOT Prev_MW6_0 AND Auto_Button_State = 0 THEN 
	MW4.7 := FALSE; MW4.8 := FALSE; MW4.9 := FALSE; MW4.10 := FALSE; MW4.11 := FALSE; MW4.15 := FALSE;
END_IF
IF MW4.15 AND NOT Prev_MW4_15 AND Auto_Button_State = 0 THEN 
	MW6.0 := FALSE; 
END_IF
IF Auto_Button_State = 0 THEN Prev_MW6_0 := MW6.0; Prev_MW4_15 := MW4.15; ELSE MW6.0 :=  Prev_MW6_0;  MW4.15:=Prev_MW4_15; END_IF
 

// Якщо CMT
IF MW6.0 THEN 
	MW4.7 := FALSE; MW4.8 := FALSE; MW4.9 := FALSE; MW4.10 := FALSE; MW4.11 := FALSE;
END_IF


IF Step = FALSE THEN
    TON_Alarm(IN := TRUE, PT := T#500MS);
    TON_Alarm2(IN := FALSE);
ELSE
    TON_Alarm2(IN := TRUE, PT := T#500MS);
    TON_Alarm(IN := FALSE);
END_IF;


// Alarm
IF (MW6.10 OR NOT(EmergencyExt)) AND Process_Auto <> 0 AND Auto_Button_State = 0 AND Alarms <> 0 THEN
	IF TON_Alarm.Q THEN
    	Process_Auto := 10;
    	Step := TRUE; 
    	TON_Alarm(IN := FALSE);
	END_IF;
	IF TON_Alarm2.Q THEN
    	Process_Auto := 11;
    	Step := FALSE; 
    	TON_Alarm2(IN := FALSE); 
	END_IF;
	MW6.9 := FALSE;
	Enable_Start := FALSE; 
	TON_Delay_Start_PF(IN:=FALSE); TON_Delay_Start_Emagnet(IN:=FALSE); TON_Delay_Start_WF(IN:=FALSE);TON_preblow(IN:=FALSE);
ELSIF NOT(MW6.11) AND Auto_Button_State = 0 THEN 
	Process_Auto := 5; 
	MW6.9 := FALSE;
	Enable_Start := FALSE;
END_IF

// Блок старту
IF NOT(MW4.3) AND Process_Auto <> 5 AND MW6.11 OR Enable_Start THEN MW6.6 := FALSE; ELSE MW6.6 := TRUE; END_IF

//Зовнішній пуск
R_TRIG_External(CLK:=StartExt);

// Local start
IF NOT(MW4.3) AND MW6.11 AND (MW6.5 AND Auto_Button_State = 0) THEN 
	IF NOT(Enable_Start) THEN
		//Are you sure
			MW6.9 := TRUE;
		Enable_Start := TRUE;
	END_IF
ELSIF MW4.3 AND R_TRIG_External.Q AND MW6.11 THEN// External start
	IF NOT(Enable_Start) THEN MW6.12 := TRUE; END_IF
	Enable_Start := TRUE;
	MW6.5 := TRUE;
END_IF
//Close are you sure
IF MW2.15 OR MW4.3 OR (NOT(MW6.11) AND Auto_Button_State = 0) OR (NOT(EmergencyExt) AND Auto_Button_State = 0) THEN Enable_Start := FALSE; MW6.9 := FALSE; MW2.15 := FALSE; MW6.5 := FALSE; END_IF

//Set process to ready
IF NOT(Enable_Start) AND MW6.11 AND Auto_Button_State = 0 THEN Process_Auto := 0; END_IF


// Start Process
IF MW6.12 AND Enable_Start AND MW6.11 THEN
	
	//Block Manual
	MW6.13 := TRUE;
	
	//Block Start
	MW6.6 := FALSE;
	
	//Close Are you sure
	MW6.9 := FALSE;
	
	//Process ON
	Auto_Button_State := 1;
	
	//Preblow
	IF Y1 AND NOT(Y2) AND NOT(Y3) AND NOT(Y4) THEN Y1 := TRUE; MW6.1:= TRUE; ELSE Y1 := MW6.1; END_IF
	IF NOT(Y1) AND Y2 AND NOT(Y3) AND NOT(Y4) THEN Y2 := TRUE; MW6.2:= TRUE;ELSE Y2 := MW6.2; END_IF
	IF NOT(Y1) AND NOT(Y2) AND Y3 AND NOT(Y4) THEN Y3 := TRUE; MW6.3:= TRUE;ELSE Y3 := MW6.3; END_IF
	IF NOT(Y1) AND NOT(Y2) AND NOT(Y3) AND Y4 THEN Y4 := TRUE; MW6.4:= TRUE;ELSE Y4 := MW6.4; END_IF
		
	IF NOT(TON_preblow.Q) THEN Process_Auto := 1; END_IF
	
	TON_preblow(IN:=Enable_Start , PT:=WORD_TO_TIME(Delay_Gas_Preblow));
	//PLASMA
	IF MW4.15 THEN 
		SetCurrent:= SetCurrent_HMI_Auto; //Current set
		//Pilot Arc
		IF TON_preblow.Q AND MW6.11 THEN 
			StartParc:= TRUE; 
			IF NOT(PilotArc) THEN Process_Auto := 2; END_IF 
		END_IF
		//Main Arc
		IF PilotArc AND StartParc THEN 
			StartMArc:= TRUE; 
			IF NOT(MainArc) THEN Process_Auto := 8; END_IF 
		END_IF
		//Additional equipment
		IF MainArc AND Process_Auto <> 3 AND StartMArc THEN Process_Auto := 9; END_IF	
		
		//Delays
		TON_Delay_Start_PF(IN:=MainArc AND StartParc AND StartMArc AND PilotArc, PT:=WORD_TO_TIME(Delay_Start_PF));
		TON_Delay_Start_WF(IN:=MainArc AND StartParc AND StartMArc AND PilotArc, PT:=WORD_TO_TIME(Delay_Start_WF));
		TON_Delay_Start_Emagnet(IN:=MainArc AND StartParc AND StartMArc AND PilotArc, PT:=WORD_TO_TIME(Delay_Start_Emagnet));
		
		IF TON_Delay_Start_PF.Q THEN
			// Transport Gases
			Y5 := MW4.7; Y6 := MW4.8; Y7 := MW4.9; Y8 := MW4.10;
			//Powder Feeder 
			PF1 := MW4.7; PF2 := MW4.8; PF3 := MW4.9; PF4 := MW4.10; 
		END_IF
		
		//Wire Feeder
		IF TON_Delay_Start_WF.Q THEN 
			IF MW4.12 THEN MF1_CW:= TRUE; MF1_CCW := FALSE; ELSE MF1_CW:= FALSE; MF1_CCW := FALSE;  END_IF
			IF MW4.13 THEN MF2_CW:= TRUE; MF2_CCW := FALSE; ELSE MF2_CW:= FALSE; MF2_CCW := FALSE;  END_IF
			IF MW4.14 THEN MF3_CW:= TRUE; MF3_CCW := FALSE; ELSE MF3_CW:= FALSE; MF3_CCW := FALSE;  END_IF
		END_IF
		
		//E-magnet
		IF TON_Delay_Start_Emagnet.Q THEN
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
			ELSE
				EM_R_EN := FALSE;
				EM_L_EN := FALSE;
				EM_R_PWM := FALSE;
				EM_L_PWM := FALSE;
				ToggleState := FALSE;
				LastToggleTime := 0;
			END_IF
		END_IF
		
		//Process
		IF (
			(NOT(MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) OR TON_Delay_Start_PF.Q) AND
			(NOT(MW4.12 OR MW4.13 OR MW4.14) OR TON_Delay_Start_WF.Q) AND
			(NOT(MW4.11) OR TON_Delay_Start_Emagnet.Q) AND
			TON_preblow.Q AND PilotArc AND MainArc
			) THEN
				Process_Auto := 3;
		END_IF

	// CMT 
	ELSIF MW6.0 AND Enable_Start AND TON_preblow.Q AND MW6.11 THEN
		CMT_PS := TRUE;
		IF Process_Auto <> 9 THEN IF Process_Auto <> 3 THEN Process_Auto := 9; END_IF END_IF
		//Wire Feeder
		TON_Delay_Start_WF(IN:=TON_preblow.Q, PT:=WORD_TO_TIME(Delay_Start_WF));
		IF TON_Delay_Start_WF.Q THEN
			IF MW4.12 THEN MF1_CW:= TRUE; MF1_CCW := FALSE; ELSE MF1_CW:= FALSE; MF1_CCW := FALSE;  END_IF
			IF MW4.13 THEN MF2_CW:= TRUE; MF2_CCW := FALSE; ELSE MF2_CW:= FALSE; MF2_CCW := FALSE;  END_IF
			IF MW4.14 THEN MF3_CW:= TRUE; MF3_CCW := FALSE; ELSE MF3_CW:= FALSE; MF3_CCW := FALSE;  END_IF
		END_IF
		IF NOT(MW4.12 OR MW4.13 OR MW4.14) OR TON_Delay_Start_WF.Q THEN
			Process_Auto := 3;
		END_IF
	END_IF
END_IF
	

//CMT Process
TON_CMT(IN:= CMT_PlusI OR CMT_MinusI, PT:= T#100MS, Q=> TON_CMT_State); //Таймер імпульсу для зміни значення
TON_CMT1(IN:= NOT(CMT_PlusI) AND NOT(CMT_MinusI), PT:= T#100MS, Q=> TON_CMT_State1); //Таймер паузи для зміни значення
IF SetCurrentCMT_HMI <> PrevCurrentCMT_HMI THEN 
	Counter:= WORD_TO_INT(SetCurrentCMT_HMI) -  WORD_TO_INT(PrevCurrentCMT_HMI); //рахуємо кількість імпульсів
	IF Counter > 0 THEN  //Якщо потрібно збільшувати струм
		IF TON_CMT_State1 THEN CMT_PlusI:= TRUE; END_IF //Імпульс
		IF TON_CMT_State THEN CMT_PlusI:= FALSE; PrevCurrentCMT_HMI:= PrevCurrentCMT_HMI +1; Counter:= Counter -1; END_IF //Пауза + інкремент
	ELSIF Counter < 0 THEN  //Якщо потрібно зменшувати струм
		IF TON_CMT_State1 THEN CMT_MinusI:= TRUE; END_IF  //Імпульс
		IF TON_CMT_State THEN CMT_MinusI:= FALSE; PrevCurrentCMT_HMI:= PrevCurrentCMT_HMI -1; Counter:= Counter +1; END_IF //Пауза + декремент
	END_IF
ELSE CMT_PlusI:= FALSE; CMT_MinusI:= FALSE; END_IF //Вимкнення інкрементального та декрементального реле по дефолту
		
//Stop
IF Process_Auto <> 0 AND Enable_Start AND ((MW4.3 AND NOT(StartExt)) AND EmergencyExt AND MW6.11 OR (NOT(MW6.5) AND Auto_Button_State = 1)) OR Auto_Button_State = 2 THEN // STOP
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
			(NOT(MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) OR (((MW4.7 OR MW4.8 OR MW4.9 OR MW4.10) AND NOT(TON_Delay_Start_PF.Q)) OR TON_Delay_Stop_PF.Q) )AND
			(NOT(MW4.12 OR MW4.13 OR MW4.14) OR (((MW4.12 OR MW4.13 OR MW4.14) AND NOT(TON_Delay_Start_WF.Q)) OR TON_Delay_Stop_WF.Q))AND
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
	ELSIF Prev_Process <> 1 AND Prev_Process <> 2 AND Prev_Process <> 8 AND Auto_Button_State <> 0 THEN
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
END_IF

IF Process_Auto = 3  THEN ProcON:= TRUE; ELSE ProcON:= FALSE; END_IF //Видача ProcON на робот

//Block local control	
IF Auto_Button_State <> 0 THEN MW8.0 := TRUE; ELSE MW8.0:= FALSE; END_IF
