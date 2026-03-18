# redfab-claude — Конфигурация 3D принтера CoreXY

Кастомный 3D принтер CoreXY на базе Klipper.
Подробная документация: [CLAUDE.md](CLAUDE.md)

## Железо
- **Основная MCU**: BTT Octopus v1.1 (STM32F446) — CAN bridge, CAN UUID: `dde4eba60f0f`
- **Тулхед**: BTT EBB 42 v1.2 (STM32G0B1) — по CAN 1 Mbps, UUID: `6269b37ddaba`
- **Драйверы**: TMC5160 SPI (X/Y/Z/Z1/Z2/Z3) + TMC2209 UART (экструдер)
- **Кинематика**: CoreXY, рабочая зона X=285 Y=440 Z=250 мм, quad gantry (4 мотора Z)
- **Нагрев стола**: 220V через MOC3063/симистор, PA8 (FAN0), PWM 50 Гц

## Статус (2026-03-17)
- [x] CAN шина Octopus ↔ EBBCan работает
- [x] Все степперы настроены (TMC5160 SPI, токи, направления)
- [x] Нагрев стола 220V, PID откалиброван (Kp=57.369 Ki=0.286 Kd=2872.015)
- [x] Sensorless хоминг X/Y (StallGuard TMC5160, SGT=2)
- [x] Хоминг Z: верхний концевик PG10, position_endstop=12.8
- [x] Нижний концевик Z: PG11 (filament_switch_sensor z_bottom)
- [x] _LOWER_Z_SAFE: безопасное опускание по 0.2 мм с проверкой z_bottom
- [x] Input shaper: mzv X=71.0 Hz Y=45.6 Hz, max_accel=5000 mm/s²
- [x] LED лента: WS2812B 30 LED, PB0, GRB, оранжевый по умолчанию
- [x] PRINT_START / PRINT_END / LOAD_FILAMENT / UNLOAD_FILAMENT / M600
- [ ] PID_CALIBRATE экструдера (TARGET=200)
- [ ] quad_gantry_level (нужен микровыключатель на EBBCan:PB8)

## Быстрый старт
```bash
ssh pi@192.168.2.20          # подключение к Pi
# http://192.168.2.20        # Mainsail веб-интерфейс
# http://192.168.2.20:7125   # Moonraker API

# Синхронизация конфигов с Pi
scp pi@192.168.2.20:~/printer_data/config/*.cfg configs/
scp pi@192.168.2.20:~/printer_data/config/moonraker.conf configs/
```

## Ссылки
- [BTT Octopus документация](https://github.com/bigtreetech/docs/blob/master/docs/Octopus.md)
- [BTT EBB 42 v1.2 схема](https://github.com/bigtreetech/EBB/tree/master/EBB%20CAN%20V1.1%20and%20V1.2)
- [Klipper docs](https://www.klipper3d.org/)
