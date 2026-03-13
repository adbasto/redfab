# Снапшот 2026-03-13 — Sensorless homing X/Y ✓

## Что сделано
- Физические концевики X и Y убраны
- Установлены DIAG джамперы: Driver0 (X, PG6), Driver1 (Y, PG9)
- Настроен sensorless homing через StallGuard TMC5160
- Подобрано финальное значение **driver_SGT: 2** для X и Y
- homing_override: G4 P1500 пауза перед G28 X и G28 Y

## Конфигурация
- `stepper.cfg` — driver_SGT: 2, virtual_endstop, homing_retract_dist: 0
- `macros.cfg` — homing_override с паузами G4 P1500

## Статус принтера на момент снапшота
- CAN шина: OK
- Нагрев стола 220V: OK, PID откалиброван
- Хоминг X: sensorless StallGuard, SGT=2 ✓
- Хоминг Y: sensorless StallGuard, SGT=2 ✓
- Хоминг Z: position_endstop=15.8, Z=0 у стола ✓
- Input shaper: mzv X=71Hz Y=45.6Hz ✓
- LED лента: WS2812B 4 LED, оранжевый по умолчанию ✓

## Нужно сделать
- PID_CALIBRATE экструдера (TARGET=200)
- quad_gantry_level (нужен микровыключатель на EBBCan:PB8)
