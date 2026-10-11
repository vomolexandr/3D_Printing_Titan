VAR
	RTRIG1: R_TRIG;
END_VAR


Measure();
Wire_Speed_Correction();
RTRIG1(CLK:= TRUE); //Тригер присвоєння струму при старті
IF RTRIG1.Q THEN PrevCurrentCMT_HMI:= SetCurrentCMT_HMI; END_IF
IF MW0.0 THEN Auto(); Alarms_auto(); ELSE  Manual(); Alarms_manual(); END_IF
