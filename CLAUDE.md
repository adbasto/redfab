# CLAUDE.md — Проект redfab-claude

Это рабочий проект настройки кастомного 3D принтера CoreXY на базе Klipper.
Здесь хранятся локальные копии конфигов с Raspberry Pi, прошивки, снапшоты и логи.

---

## Железо

### Основная плата — BTT Octopus v1.1 (STM32F446)
- Роль: главная MCU + USB→CAN bridge (gs_usb)
- CAN UUID: `dde4eba60f0f`
- Прошивка: `firmware/klipper_octopus_f446_canbridge_20260206.bin`
- Драйверы: TMC5160 (SPI, spi1) для X/Y/Z/Z1/Z2/Z3

### Тулхед — BTT EBB 42 v1.2 (STM32G0B1)
- Роль: экструдер, хотенд, вентиляторы, датчики, ADXL345
- CAN UUID: `6269b37ddaba`
- CAN bus: 1 Mbps, пины PB0/PB1
- Прошивка: `firmware/klipper_ebb42_stm32g0b1_can_1m.bin`
- Драйвер экструдера: TMC2209 (UART, PA15)

### Кинематика
- Тип: CoreXY
- Рабочая зона: X=285, Y=440, Z=250 мм
- Z: 4 независимых мотора (quad_gantry_level)
- Редуктор Z: 80:20 (шестерня к ремню), rotation_distance=32 (откалибровано)

### Нагрев стола
- 220V нагревательный элемент
- Управление: PA8 (FAN0) → оптопара MOC3063 → симистор/триак
- Термистор: NTC 100K Generic 3950 на PF3
- PWM: 50 Гц (pwm_cycle_time=0.02) для zero-crossing

### Датчики
| Датчик | Пин | Статус |
|--------|-----|--------|
| X sensorless | PG6 (DIAG) | StallGuard TMC5160, driver_SGT=2, физический концевик убран |
| Y sensorless | PG9 (DIAG) | StallGuard TMC5160, driver_SGT=2, физический концевик убран |
| Z endstop верхний | PG10 (^) | хоминг Z, position_endstop=15.8 |
| Z endstop нижний | PG11 (^) | ограничитель опускания, filament_switch_sensor z_bottom |
| Z probe | EBBCan:PB8 (^!) | настроен, датчик не установлен физически |
| ADXL345 | EBBCan:PB12 (SPI2) | работает, для input shaper |
| Датчик филамента | EBBCan:PB3 (^) | настроен |
| Ёмкостный датчик | EBBCan:PA4 | аналоговый, отображается на графике (0–330) |
| Термистор стола | PF3 | работает |
| Термистор хотенда | EBBCan:PA3 | настроен |
| Темп. Raspberry Pi | host | отображается |

---

## Доступ

| Ресурс | Адрес |
|--------|-------|
| SSH | `pi@192.168.2.20` (ключ, без пароля) |
| Mainsail UI | `http://192.168.2.20` |
| Moonraker API | `http://192.168.2.20:7125` |
| Конфиги на Pi | `~/printer_data/config/` |
| Логи Klipper | `~/printer_data/logs/klippy.log` |

---

## Структура проекта

```
redfab-claude/
├── CLAUDE.md              ← этот файл
├── README.md              ← ссылки и документация
├── session.log            ← лог команд и решений
│
├── configs/               ← актуальные конфиги (синхронизированы с Pi)
│   ├── printer.cfg        ← главный конфиг (includes, MCU, heater_bed, printer)
│   ├── core.cfg           ← температурные сенсоры (RPi temp)
│   ├── stepper.cfg        ← все степперы X/Y/Z/Z1/Z2/Z3 + TMC
│   ├── ebb_can.cfg        ← тулхед: экструдер, вентиляторы, probe, ADXL345
│   ├── macros.cfg         ← homing_override и пользовательские макросы
│   ├── leds.cfg           ← WS2812B лента (PB0, 30 LED, GRB, оранжевый)
│   ├── debug.cfg          ← force_move, диагностические макросы
│   ├── moonraker.conf     ← API сервер
│   ├── crowsnest.conf     ← веб-камера
│   ├── sonar.conf         ← мониторинг
│   ├── calibration/       ← CSV данные калибровок (input shaper и др.)
│   └── archive/           ← старые/референсные конфиги
│
├── firmware/              ← бинарники прошивок MCU
│   ├── klipper_octopus_f446_canbridge_20260206.bin
│   └── klipper_ebb42_stm32g0b1_can_1m.bin
│
└── snapshots/             ← точки восстановления
    ├── snapshot-2026-03-06/   ← стол 220V работает, PID откалиброван
    ├── snapshot-2026-03-10/   ← ADXL345 работает
    ├── snapshot-2026-03-10b/  ← XY хоминг (X=0 слева, Y=350 сзади) ✓
    ├── snapshot-2026-03-10c/  ← homing_override с опусканием Z перед XY
    ├── snapshot-2026-03-11/   ← ПРИНТЕР ГОТОВ К ПЕЧАТИ ✓ (Z калибровка, shaper, LED)
    ├── snapshot-2026-03-12/
    ├── snapshot-2026-03-13/   ← sensorless homing X/Y (SGT=2) ✓
    ├── snapshot-2026-03-16/   ← расширенный homing, нижний концевик Z PG11, ёмкостный датчик PA4
    └── snapshot-2026-03-17/   ← PRINT_START/PRINT_END, смена филамента, прайм-линия (текущий)
```

---

## Пины Octopus (ключевые назначения)

| Функция | Пин | Примечание |
|---------|-----|------------|
| Stepper X STEP/DIR/EN | PF13/PF12/PF14 | TMC5160, cs=PC4 |
| Stepper Y STEP/DIR/EN | PG0/PG1/PF15 | TMC5160, cs=PD11 |
| Stepper Z STEP/DIR/EN | PF11/PG3/PG5 | TMC5160, cs=PC6 |
| Stepper Z1 | PG4/PC1/PA0 | TMC5160, cs=PC7 |
| Stepper Z2 | PF9/PF10/PG2 | TMC5160, cs=PF2 |
| Stepper Z3 | PC13/PF0/PF1 | TMC5160, cs=PE4 |
| X endstop (DIAG sensorless) | PG6 | |
| Y endstop (DIAG sensorless) | PG9 | |
| Z endstop верхний (хоминг) | PG10 | |
| Z endstop нижний (ограничитель) | PG11 | filament_switch_sensor z_bottom |
| Нагрев стола | PA8 (FAN0) | 220V через MOC3063 |
| Термистор стола | PF3 | Generic 3950, 100K |
| Neopixel (лента) | PB0 | WS2812B, 30 LED, GRB |

## Пины EBB 42 v1.2 (ключевые назначения)

| Функция | Пин | Примечание |
|---------|-----|------------|
| Экструдер STEP/DIR/EN | PD0/PD1/PD2 | TMC2209 UART=PA15 |
| Нагрев хотенда | PB13 | |
| Термистор хотенда | PA3 | Generic 3950 |
| Обдув пластика (FAN0) | PA0 | |
| Охлаждение хотенда (FAN1) | PA1 | авто при T>50°C |
| Z probe сенсор | PB8 | ^! (pull-up + инверсия) |
| BLTouch servo | PB9 | |
| ADXL345 CS | PB12 | SPI2: PB2/PB11/PB10 |
| ADXL345 INT1/INT2 | — | NC, не разведены! |
| Датчик филамента | PB3 | ^ pull-up |

---

## PID значения (откалиброваны)

| Нагреватель | Kp | Ki | Kd |
|------------|----|----|-----|
| Стол (target=60) | 57.369 | 0.286 | 2872.015 |
| Экструдер | 29.581 | 4.287 | 51.028 |

---

## Текущий статус и что осталось

### Работает ✓
- [x] CAN шина Octopus ↔ EBBCan
- [x] Все степперы настроены (токи, направления)
- [x] Нагрев стола 220V, PID откалиброван (Kp=57.369 Ki=0.286 Kd=2872.015)
- [x] ADXL345 работает
- [x] Датчик филамента настроен
- [x] Хоминг X: sensorless StallGuard PG6, position_endstop=-35, отъезд к X=0 ✓
- [x] Хоминг Y: sensorless StallGuard PG9, position_endstop=441, отъезд к Y=440 ✓
- [x] Хоминг Z: верхний концевик PG10, position_endstop=15.8 ✓
- [x] homing_override полный: G28 X → X=0 → G28 Y → Y=440 → G28 X (фиксация) → парковка X=285 Y=0 → нагрев 230°C → чистка сопла → _LOWER_Z_SAFE → X=-25 Y=114 → G28 Z → парковка X=285 Y=0 Z=5
- [x] Нижний концевик Z: PG11, filament_switch_sensor z_bottom, ограничивает опускание стола ✓
- [x] _LOWER_Z_SAFE: безопасное опускание по 0.2мм с проверкой нижнего концевика (макс 20мм) ✓
- [x] Рабочая зона: X=285, Y=440, Z=250 мм
- [x] rotation_distance Z: 32, экструдера: 5.44
- [x] Input shaper: mzv X=71.0Hz Y=45.6Hz, max_accel=5000 mm/s² ✓
- [x] Адресная лента WS2812B: 30 LED, PB0, GRB, оранжевый по умолчанию
- [x] Ёмкостный датчик: EBBCan:PA4, аналоговый, шкала 0–330 (= напряжение × 100) ✓

- [x] PRINT_START: нагрев стола во время хоминга, прайм 30мм, 2 прохода прайм-линии со смещением 0.5мм ✓
- [x] PRINT_END: парковка X=285 Y=0, стол вниз максимально, выключение всего ✓
- [x] LOAD_FILAMENT / UNLOAD_FILAMENT / M600 / FILAMENT_LOADED — смена филамента ✓
- [x] max_extrude_cross_section: 2.0 (исправлена ошибка превышения сечения экструзии) ✓
- [x] position_endstop Z: 12.8 (откалибровано) ✓

### Нужно сделать
- [ ] PID_CALIBRATE для экструдера (при рабочей температуре 200°C)
- [ ] quad_gantry_level — выровнять портал (нужен микровыключатель на EBBCan:PB8)
- [ ] PROBE_CALIBRATE — Z offset (нужен тот же датчик на PB8)

---

## Важные команды

```gcode
# Диагностика
QUERY_PROBE           ; состояние Z probe
ACCELEROMETER_QUERY   ; тест ADXL345
QUERY_ADC NAME=heater_bed ; напряжение на термисторе стола

# Движение без хоминга (force_move включён)
SET_KINEMATIC_POSITION Z=0
G91
G1 Z10 F300

# Калибровки
PID_CALIBRATE HEATER=heater_bed TARGET=60
PROBE_CALIBRATE
SHAPER_CALIBRATE
```

---

## Координатная система (актуально 2026-03-16)

| Ось | Концевик | Пин | Позиция | dir_pin |
|-----|----------|-----|---------|---------|
| X | DIAG sensorless | PG6 | position_endstop=-35, рабочий диапазон -35..285 | !PF12 |
| Y | DIAG sensorless | PG9 | position_endstop=441, отъезд к Y=440 | !PG1 (homing_positive_dir: true) |
| Z верхний | Физический NC | PG10 | position_endstop=15.8, Z=0 у стола | !PG3 (homing_positive_dir: false) |
| Z нижний | Физический | PG11 | ограничитель (filament_switch_sensor z_bottom) | — |

- Z=0 = сопло у стола, Z+ = стол вниз
- Z верхний и нижний концевики теперь на **разных пинах**: PG10 (хоминг) и PG11 (ограничитель)
- Позиция под Z концевик: **X=-25, Y=114**
- После хоминга X: отъезд к X=0. После хоминга Y: отъезд к Y=440.

---

## Заметки по ADXL345 как Z probe

Исследовано 2026-03-10:
- ADXL345 читает все 3 оси корректно
- В покое Z: mean=-242, stddev=527 мм/с², шум высокий
- tap detection через INT1/INT2 **не работает** — пины NC на EBB 42 v1.2
- Чтение через SPI→CAN→Pi: задержка 5–20 мс, непригодно для endstop
- Проект adxl345-probe требует пайки к ноге чипа INT1
- **Решение**: установить микровыключатель на PB8

---

## Синхронизация конфигов (Pi → локально)

```bash
scp pi@192.168.2.20:~/printer_data/config/printer.cfg configs/
scp pi@192.168.2.20:~/printer_data/config/\*.cfg configs/
scp pi@192.168.2.20:~/printer_data/config/moonraker.conf configs/
```
