# Снапшот 2026-03-11 — Принтер готов к печати ✓

## Статус: РАБОЧИЙ

Все основные калибровки выполнены, принтер готов к первой печати.

## Что откалибровано

| Система | Статус | Параметры |
|---------|--------|-----------|
| XY хоминг | ✓ | X=0 левый (PG6), Y=350 задний (PG9) |
| Z хоминг | ✓ | position_endstop: 15.8, Z=0 проверен бумагой |
| Стол PID | ✓ | Kp=57.369 Ki=0.286 Kd=2872.015 |
| Input shaper | ✓ | mzv X=71.0Hz, Y=45.6Hz |
| rotation_distance | ✓ | экструдер: 5.44 (калибровался ранее) |
| max_accel | ✓ | 5000 mm/s² (лимит Y: 6100) |

## Что ещё нужно сделать

- [ ] Экструдер PID (`PID_CALIBRATE HEATER=extruder TARGET=200`)
- [ ] Выравнивание портала quad_gantry_level (нужен датчик на EBBCan:PB8)

## homing_override (macros.cfg)

```
G28 → опустить Z на 20мм → G28 X → G28 Y → G1 X9 Y27 → G28 Z
```

## Файлы калибровки ADXL345
- `calibration_data_x_20260311_135157.csv`
- `calibration_data_y_20260311_135157.csv`

## Восстановление
```bash
scp snapshots/snapshot-2026-03-11/*.cfg pi@192.168.2.20:~/printer_data/config/
scp snapshots/snapshot-2026-03-11/moonraker.conf pi@192.168.2.20:~/printer_data/config/
# Затем FIRMWARE_RESTART в Mainsail
```
