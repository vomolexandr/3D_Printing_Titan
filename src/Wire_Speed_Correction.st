VAR
	New_WF1_SPD: WORD;
	LastCorrTime: ULINT := 0;
	TimeDiff: TIME;
	CurrentTime_WF: ULINT;
	LastTime_WF: ULINT := 0;
	Wanted_Speed_WF1: REAL;
	Wanted_Speed_WF2: REAL;
	Wanted_Speed_WF3: REAL;
	HMI_Old_WF1: WORD;
	HMI_Old_WF2: WORD;
	New_WF2_SPD: WORD;
	HMI_Old_WF3: WORD;
	New_WF3_SPD: WORD;
END_VAR


// Отримання поточного часу в мікросекундах
SysTimeGetUs(CurrentTime_WF);

// Розрахунок бажаної швидкості в імпульсах
IF MW0.0 THEN
	Wanted_Speed_WF1 := (WORD_TO_REAL(WF1_SPD_HMI_Auto) - 6000.0) * ((1700.0-100.0) / (20000.0-6000.0)) + 100.0;
	Wanted_Speed_WF2 := (WORD_TO_REAL(WF2_SPD_HMI_Auto) - 6000.0) * ((1700.0-100.0) / (20000.0-6000.0)) + 100.0;
	Wanted_Speed_WF3 := (WORD_TO_REAL(WF3_SPD_HMI_Auto) - 6000.0) * ((1700.0-100.0) / (20000.0-6000.0)) + 100.0;
			// Ініціалізація
	IF HMI_Old_WF1 <> WF1_SPD_HMI_Auto AND MW4.12 AND Process_Auto = 3 THEN HMI_Old_WF1 := WF1_SPD_HMI_Auto; New_WF1_SPD := HMI_Old_WF1; END_IF
	IF HMI_Old_WF2 <> WF2_SPD_HMI_Auto AND MW4.13 AND Process_Auto = 3 THEN HMI_Old_WF2 := WF2_SPD_HMI_Auto; New_WF2_SPD := HMI_Old_WF2; END_IF
	IF HMI_Old_WF3 <> WF3_SPD_HMI_Auto AND MW4.14 AND Process_Auto = 3 THEN HMI_Old_WF3 := WF3_SPD_HMI_Auto; New_WF3_SPD := HMI_Old_WF3; END_IF
ELSE
	Wanted_Speed_WF1 := (WORD_TO_REAL(WF1_SPD_HMI_Man) - 6000.0) * ((1700.0-100.0) / (20000.0-6000.0)) + 100.0;
	Wanted_Speed_WF2 := (WORD_TO_REAL(WF2_SPD_HMI_Man) - 6000.0) * ((1700.0-100.0) / (20000.0-6000.0)) + 100.0;
	Wanted_Speed_WF3 := (WORD_TO_REAL(WF3_SPD_HMI_Man) - 6000.0) * ((1700.0-100.0) / (20000.0-6000.0)) + 100.0;
		// Ініціалізація
	IF HMI_Old_WF1 <> WF1_SPD_HMI_Man AND MW2.04 THEN HMI_Old_WF1 := WF1_SPD_HMI_Man; New_WF1_SPD := HMI_Old_WF1; END_IF
	IF HMI_Old_WF2 <> WF2_SPD_HMI_Man AND MW2.06 THEN HMI_Old_WF2 := WF2_SPD_HMI_Man; New_WF2_SPD := HMI_Old_WF2; END_IF
	IF HMI_Old_WF3 <> WF3_SPD_HMI_Man AND MW2.08 THEN HMI_Old_WF3 := WF3_SPD_HMI_Man; New_WF3_SPD := HMI_Old_WF3; END_IF
END_IF


// Обчислення раз на секунду
	IF (CurrentTime_WF - LastTime_WF) >= REAL_TO_ULINT(100_000.0) THEN
		//WF1
		IF MW2.04 OR (MW4.12 AND Process_Auto = 3) THEN
		 	IF Wanted_Speed_WF1 - Freq_WF1 > 5.0 THEN New_WF1_SPD := New_WF1_SPD + 37; ELSIF Freq_WF1 - Wanted_Speed_WF1 > 5.0 THEN New_WF1_SPD := New_WF1_SPD - 37; END_IF
			 	LastTime_WF := CurrentTime_WF; // обнулення таймера
		END_IF
		//WF2
   		IF MW2.06 OR (MW4.13 AND Process_Auto = 3) THEN
		 	IF Wanted_Speed_WF2 - Freq_WF2 > 5.0 THEN New_WF2_SPD := New_WF2_SPD + 37; ELSIF Freq_WF2 - Wanted_Speed_WF2 > 5.0 THEN New_WF2_SPD := New_WF2_SPD - 37; END_IF
			 	LastTime_WF := CurrentTime_WF; // обнулення таймера
		END_IF
		//WF3
		IF MW2.08 OR (MW4.14 AND Process_Auto = 3) THEN
		 	IF Wanted_Speed_WF3 - Freq_WF3 > 5.0 THEN New_WF3_SPD := New_WF3_SPD + 37; ELSIF Freq_WF3 - Wanted_Speed_WF3 > 5.0 THEN New_WF3_SPD := New_WF3_SPD - 37; END_IF
			 	LastTime_WF := CurrentTime_WF; // обнулення таймера
		END_IF
	END_IF


// Обмеження діапазону напруги
IF New_WF1_SPD > 20000 THEN New_WF1_SPD := 20000; ELSIF New_WF1_SPD < 6000 THEN New_WF1_SPD := 6000; END_IF
IF New_WF2_SPD > 20000 THEN New_WF2_SPD := 20000; ELSIF New_WF2_SPD < 6000 THEN New_WF2_SPD := 6000; END_IF
IF New_WF3_SPD > 20000 THEN New_WF3_SPD := 20000; ELSIF New_WF3_SPD < 6000 THEN New_WF3_SPD := 6000; END_IF

// Встановлення остаточного значення
WF1_SPD := NEW_WF1_SPD;
WF2_SPD := NEW_WF2_SPD;
WF3_SPD := NEW_WF3_SPD;
