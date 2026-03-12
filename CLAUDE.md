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
- Рабочая зона: 300×350×350 мм
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
| X endstop | PG6 | работает, X=0 у левого концевика |
| Y endstop | PG9 | работает, Y=350 у заднего концевика |
| Z endstop верхний | PG10 (^) | хоминг Z, position_endstop=15.8 |
| Z endstop нижний | PG10 (^) | тот же пин, физический упор снизу |
| Z probe | EBBCan:PB8 (^!) | настроен, датчик не установлен физически |
| ADXL345 | EBBCan:PB12 (SPI2) | работает, для input shaper |
| Датчик филамента | EBBCan:PB3 (^) | настроен |
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
    └── snapshot-2026-03-12/   ← (текущий)
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
| X endstop | PG6 | |
| Y endstop | PG9 | |
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
- [x] Хоминг X: X=0 у левого концевика (PG6) ✓
- [x] Хоминг Y: Y=350 у заднего концевика (PG9) ✓
- [x] Хоминг Z: position_endstop=15.8, Z=0 проверен бумагой ✓
- [x] homing_override: опустить Z на 20мм → G28 X → G28 Y → G1 X9 Y27 → G28 Z
- [x] rotation_distance Z: 32 (откалибровано: 200мм → реально 160мм → коэф. 0.8)
- [x] Input shaper: mzv X=71.0Hz Y=45.6Hz, max_accel=5000 mm/s² ✓
- [x] rotation_distance экструдера: 5.44 (откалибровано ранее)
- [x] Адресная лента WS2812B: 30 LED, PB0, GRB, оранжевый по умолчанию

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

## Координатная система (откалибровано 2026-03-10/11)

| Ось | Концевик | Пин | Позиция | dir_pin |
|-----|----------|-----|---------|---------|
| X | Левый | PG6 | X=0 | !PF12 |
| Y | Задний | PG9 | Y=350 | !PG1 (homing_positive_dir: true) |
| Z | Верхний | PG10 | Z=15.8 (концевик), Z=0 (сопло у стола) | !PG3 (homing_positive_dir: false) |

- Z=0 = сопло у стола, Z+ = стол вниз
- Оба Z концевика (верхний и нижний) на одном пине PG10
- Позиция под Z концевик: **X=9, Y=27** (9мм от левого, 27мм от переднего края)

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
