VAR
	TON0: TON;
	TON0_State: BOOL;
	TON2: TON;
	TON1: TON;
	TON_Emergency_Man: BOOL;
	TON3: TON;
END_VAR

TON0(IN:= MW2.0, PT:= WORD_TO_TIME(Check_Voltage_Current_Delay), Q=> TON0_State); //Затримка аналізу аварій

TON2(IN:=  ErrorInManual = 11, PT:= T#1000MS); //Таймер блимання помилки
TON3(IN:=  ErrorInManual = 10, PT:= T#1000MS); //Таймер блимання помилки
IF NOT(MW0.7) THEN ErrorInManual:= 11;
	ELSIF ErrorInManual = 11 AND TON2.Q THEN ErrorInManual:= 10; //Перемикання блималки
	ELSIF ErrorInManual = 10 AND TON3.Q THEN ErrorInManual:= 11; //Перемикання блималки
END_IF

IF TON0_State THEN
	IF Set_Emergency_Voltage > MeasureU AND MW4.0 THEN MW0.7 := TRUE; Alarms := 1; END_IF
	IF Set_Emergency_Current > MeasureI AND MW4.1 THEN MW0.7 := TRUE; Alarms := 2; END_IF
END_IF

IF NOT(MW0.7) AND EmergencyExt AND Alarms = 0 THEN MW0.6 := TRUE; ELSE MW0.6 := FALSE; END_IF//Готовність

IF MW0.7 OR NOT(EmergencyExt) THEN MW0.6 := FALSE; END_IF // Скидання готовності

IF MW0.7 AND Alarms = 0 AND EmergencyExt THEN MW0.7 := FALSE; END_IF
IF NOT(EmergencyExt) THEN Alarms := 3; MW0.7 := TRUE; END_IF // Ввікнення аварії при нажатій кнопці Emergency stop

TON1(IN:= MW0.7 OR NOT(EmergencyExt), PT:= WORD_TO_TIME(Emergency_Delay), Q=> TON_Emergency_Man); //Затримка аварійного вимкнення

//Аварійна зупинка
IF TON_Emergency_Man THEN MW4.2 := TRUE; MW4.4 := TRUE; MW4.6 := TRUE; MW2.0 := FALSE; MW2.1 := FALSE; MW2.10 := FALSE; MW2.11 := FALSE; MW2.12 := FALSE; MW2.13 := FALSE; MW2.4 := FALSE; MW2.6 := FALSE; MW2.8 := FALSE; MW2.2 := FALSE; MW2.14 := FALSE; END_IF

IF MW4.5 THEN Alarms := 0; MW0.7 := FALSE; END_IF //Скидання аларму
