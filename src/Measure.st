VAR
	R_TRIG_WF1: R_TRIG;
	R_TRIG_WF3: R_TRIG;
	R_TRIG_WF2: R_TRIG;
	TON_READY_EXT: TON;
	STATE_READY_EXT: BOOL;
	ReadyExt_Prev: BOOL;
	ReadyExt_Reset: BOOL;
	PArc_trig: R_TRIG;
END_VAR

IF ReadyExt <> ReadyExt_Prev THEN ReadyExt_Reset:= FALSE; ReadyExt_Prev:= ReadyExt; ELSE  ReadyExt_Reset:= TRUE; END_IF //Обнулення лічильника Ready ext
TON_READY_EXT(IN:= ReadyExt_Reset, PT:= T#150MS, Q=> STATE_READY_EXT); //Лічильник Ready ext
MeasureU_MHI:= MeasureU;
MeasureI_MHI:= MeasureI;
MW0.1:= StartExt;
MW0.2:= NOT(STATE_READY_EXT);
MW0.3:= NOT(EmergencyExt);
MW0.4:= PilotArcIN; 
MW0.5:= MainArc;

PArc_trig(CLK:= PilotArcIN); //Тригер наявності черг дуг
IF PArc_trig.Q THEN PilotArc:= TRUE; END_IF //Взведення флажка черг дуг
IF NOT(StartParc) THEN PilotArc:= FALSE; END_IF //Скидання флажка черг дуг

// Ввікмнення лічильника імпульсів
//WF1
HSC0.EN_Enable := TRUE;
HSC0.F_Enable := TRUE;
HSC0();
Freq_WF1 := DINT_TO_REAL(HSC0.CurrentValue);
//WF2
HSC1.EN_Enable := TRUE;
HSC1.F_Enable := TRUE;
HSC1();
Freq_WF2 := DINT_TO_REAL(HSC1.CurrentValue);
//WF3
HSC2.EN_Enable := TRUE;
HSC2.F_Enable := TRUE;
HSC2();
Freq_WF2 := DINT_TO_REAL(HSC2.CurrentValue);

PArcON:= PilotArc; //Pilot arc ON for robot
