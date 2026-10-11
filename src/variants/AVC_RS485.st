// Варіант з командою вимірювання по Modbus RS485 (біт 0 слова IW19) замість дискретного входу IX0.7.
// Решта програми збігається з основною версією.
VAR
	PID_1: PID;
	RAMP_INT_1: RAMP_INT;
	TON_AVC: TON;
	TON_StopConfirm: TON;
	Robot_MeasureCmd_Raw: BOOL;
END_VAR

// Визначення фронтів одного сигналу
// Сирий сигнал з Modbus
Robot_MeasureCmd_Raw := IW19.0;

// Підтвердження нуля, щоб короткий провал зв'язку не давав фальшивий STOP
TON_StopConfirm(IN := NOT Robot_MeasureCmd_Raw, PT := T#50MS);

IF Robot_MeasureCmd_Raw THEN
    Robot_MeasureCmd := TRUE;
ELSIF TON_StopConfirm.Q THEN
    Robot_MeasureCmd := FALSE;
END_IF

StartEvent := Robot_MeasureCmd AND NOT Robot_MeasureCmd_Prev;
StopEvent := NOT Robot_MeasureCmd AND Robot_MeasureCmd_Prev;

TON_AVC(IN:= NOT Robot_MeasureCmd, PT:= T#5000MS); //Захист від надсилання старих даних
IF TON_AVC.Q THEN QW13:= 0; END_IF //Захист від надсилання старих даних

// START: сигнал від робота перейшов 0 -> 1
IF StartEvent THEN
    Measuring := TRUE; MeasureDone := FALSE; MeasureStatus := 1; VoltageSum := 0.0; SampleCount := 0; VoltageAverage := 0.0; VoltageFiltered := 0.0; FirstSample := TRUE; END_IF;

// Вимірювання, поки Robot_MeasureCmd = TRUE
IF Measuring AND Robot_MeasureCmd THEN
    VoltageRaw := WORD_TO_REAL(MeasureU) / 1000.0;
    SampleValid := (VoltageRaw >= VoltageMin) AND (VoltageRaw <= VoltageMax); // Перевірка допустимого діапазону
    IF SampleValid THEN
        IF FirstSample THEN
            VoltageFiltered := VoltageRaw;
            FirstSample := FALSE;
            VoltageSum := VoltageSum + VoltageFiltered;
            SampleCount := SampleCount + 1;
        ELSE
            IF ABS(VoltageRaw - VoltageFiltered) <= MaxJump THEN // Захист від одиночних викидів
                VoltageFiltered := VoltageFiltered + K_Filter * (VoltageRaw - VoltageFiltered); // EMA-фільтр
                VoltageSum := VoltageSum + VoltageFiltered; // Накопичення середнього по відфільтрованому сигналу
                SampleCount := SampleCount + 1;
            END_IF;
        END_IF;
    END_IF;
END_IF;

// STOP: сигнал від робота перейшов 1 -> 0
IF StopEvent THEN
    Measuring := FALSE;
    IF SampleCount > 0 THEN
        VoltageAverage := VoltageSum / DINT_TO_REAL(SampleCount); VoltageAverage_x100 := REAL_TO_WORD(VoltageAverage * 100.0); MeasureStatus := 2;
    ELSE
        VoltageAverage := 0.0; VoltageAverage_x100 := 0; MeasureStatus := 3;
    END_IF;
    MeasureDone := TRUE;
	QW13:= VoltageAverage_x100;
END_IF;

// Запам'ятовуємо попередній стан сигналу
Robot_MeasureCmd_Prev := Robot_MeasureCmd;
