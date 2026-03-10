# ТОЧКА ВОССТАНОВЛЕНИЯ — 2026-03-06
# Кастомный CoreXY принтер (redfab)
# Klipper commit: 187481e25 (mainline)

========================================================================
СОСТОЯНИЕ НА МОМЕНТ СНАПШОТА
========================================================================

Что работает:
  ✓ CAN шина (Octopus как bridge → EBB 42), 1 Mbps
  ✓ Оба MCU подключены и настроены в Klipper
  ✓ Все моторы X/Y/Z0-Z3 + экструдер настроены (TMC5160/TMC2209)
  ✓ Термистор стола (NTC 100K B3950, PF3), показания корректны
  ✓ Нагрев стола 220V через MOC3063 (PA8), PID откалиброван
  ✓ Хотенд (NTC 100K B3950), PID откалиброван
  ✓ Датчик филамента (EBBCan:PB3)
  ✓ Вентиляторы (деталь PA0, хотенд PA1)
  ✓ force_move включён (движение без хоминга через SET_KINEMATIC_POSITION)
  ✓ ADXL345 настроен (для input shaper)
  ✓ Probe сконфигурирован на EBBCan:PB8 (ждёт физический датчик)

Что НЕ сделано / требует физических действий:
  ✗ Z probe — нужен микровыключатель или BLTouch в разъём PB8/PB9 на EBB 42
  ✗ Хоминг XY — не тестировался
  ✗ quad_gantry_level — не настроен
  ✗ Z offset — не откалиброван
  ✗ Input shaper (ADXL345) — настроен в конфиге, не откалиброван
  ✗ Калибровка экструдера — не проверялась

ВАЖНО: ADXL345 не может быть Z probe в Klipper (ни mainline, ни Kalico).
       Единственный вариант — физический датчик на PB8.

========================================================================
ЖЕЛЕЗО
========================================================================

Raspberry Pi 4 (MainsailOS 6.12.62+rpt-rpi-2712)
  IP: 192.168.2.20
  SSH: pi@192.168.2.20 (по ключу, без пароля)
  Mainsail: http://192.168.2.20
  Moonraker API: http://192.168.2.20:7125

BTT Octopus v1.1 F446
  Роль: главная MCU + USB→CAN bridge (gs_usb, ID 1d50:606f)
  canbus_uuid: dde4eba60f0f
  Прошивка: klipper_octopus_f446_canbridge_20260206.bin

BTT EBB 42 v1.2 (STM32G0B1)
  Роль: тулхед (экструдер, хотенд, вентиляторы, датчики)
  canbus_uuid: 6269b37ddaba
  Прошивка: klipper_ebb42_stm32g0b1_can_1m.bin
  Встроен ADXL345: cs=PB12, spi=spi2_PB2_PB11_PB10

CAN шина: 1 000 000 bps, терминаторы 120 Ом на обоих концах

========================================================================
ПИНЫ EBB 42 v1.2 (важные)
========================================================================

  PB8  — PROBE sensor input (концевик/датчик зонда)
  PB9  — BLTouch control (серво управление)
  PB12 — ADXL345 CS
  PB10 — ADXL345 SCK (spi2)
  PB11 — ADXL345 MOSI (spi2)
  PB2  — ADXL345 MISO (spi2)
  PB3  — датчик филамента (filament sensor)
  PB13 — нагреватель хотенда
  PA3  — термистор хотенда
  PA0  — FAN0 (деталь)
  PA1  — FAN1 (хотенд)
  PA15 — TMC2209 UART
  PD0  — шаговик step
  PD1  — шаговик dir
  PD2  — шаговик enable

========================================================================
СТРУКТУРА КОНФИГОВ
========================================================================

~/printer_data/config/
  printer.cfg    — главный: includes, MCU UUID, heater_bed, safe_z_home
  core.cfg       — температурный сенсор Pi
  stepper.cfg    — все моторы X/Y/Z0-Z3
  ebb_can.cfg    — экструдер, вентиляторы, adxl345, probe, датчик филамента
  debug.cfg      — force_move, PROBE_STATE макрос, TEST_HOME_X макрос
  moonraker.conf — конфиг Moonraker

========================================================================
КАК ВОССТАНОВИТЬ С НУЛЯ
========================================================================

ШАГ 1 — CAN интерфейс на Pi
  sudo nano /etc/network/interfaces.d/can0
  ---
  allow-hotplug can0
  iface can0 can static
      bitrate 1000000
      up ip link set $IFACE txqueuelen 1024
  ---
  sudo systemctl restart networking
  Проверка: ip -details link show can0  → UP, bitrate 1000000

ШАГ 2 — Прошивка EBB 42 (если слетела):
  1. Подключить USB к Pi, зажать BOOT0, нажать RESET, отпустить BOOT0
  2. lsusb | grep '0483:df11'
  3. echo 'raspberry' | sudo -S dfu-util -a 0 \
       -D ~/klipper/out/klipper.bin \
       --dfuse-address 0x08000000:force:mass-erase:leave \
       -d 0483:df11

ШАГ 3 — Копирование конфигов:
  for f in printer.cfg core.cfg stepper.cfg ebb_can.cfg debug.cfg moonraker.conf; do
    scp snapshot-2026-03-06/$f pi@192.168.2.20:~/printer_data/config/$f
  done

ШАГ 4 — Перезапуск:
  curl -X POST http://192.168.2.20:7125/printer/restart

ШАГ 5 — Проверка (klippy.log):
  Loaded MCU 'mcu' 151 commands      ← OK
  Loaded MCU 'EBBCan' 138 commands   ← OK
  Configured MCU 'mcu' (1024 moves)
  Configured MCU 'EBBCan' (1024 moves)

========================================================================
КЛЮЧЕВЫЕ ПАРАМЕТРЫ
========================================================================

MCU canbus UUID:
  Octopus: dde4eba60f0f
  EBBCan:  6269b37ddaba

PID стола (60°C): Kp=57.369  Ki=0.286   Kd=2872.015
PID хотенда:      Kp=29.581  Ki=4.287   Kd=51.028

Нагрев стола: 220V AC, PA8 (FAN0) → MOC3063 → триак, pwm_cycle_time=0.02
Экструдер: rotation_distance=5.44, TMC2209 @ 0.8A
Моторы X/Y/Z: TMC5160 @ 1.1A, sense_resistor=0.075, spi1, rotation_distance=40
Z gear_ratio: 80:20

========================================================================
СЛЕДУЮЩИЕ ШАГИ
========================================================================

1. Подключить микровыключатель в PB8 на EBB 42 → Z probe заработает сразу
   (или BLTouch: sensor_pin=PB8, control_pin=PB9)

2. Протестировать хоминг: G28 X, затем G28 Y

3. Добавить [quad_gantry_level] в printer.cfg

4. PROBE_CALIBRATE → Z offset

5. Input shaper: SHAPER_CALIBRATE (ADXL345 уже настроен)

========================================================================
ПОЛЕЗНЫЕ КОМАНДЫ
========================================================================

# Движение без хоминга
SET_KINEMATIC_POSITION X=150 Y=150 Z=50
G91 / G1 Z50 F300 / G90

# Состояние probe
QUERY_PROBE
PROBE_STATE

# Firmware restart после shutdown
curl -X POST http://192.168.2.20:7125/printer/firmware_restart

# Лог Klipper
ssh pi@192.168.2.20 'tail -50 ~/printer_data/logs/klippy.log'
