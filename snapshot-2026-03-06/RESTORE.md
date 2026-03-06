# ТОЧКА ВОССТАНОВЛЕНИЯ — 2026-03-06
# Кастомный CoreXY принтер (redfab)
# Klipper commit: 187481e25

========================================================================
СОСТОЯНИЕ НА МОМЕНТ СНАПШОТА
========================================================================

Что работает:
  ✓ CAN шина (Octopus как bridge → EBB 42), 1 Mbps
  ✓ Оба MCU подключены и настроены в Klipper
  ✓ Все моторы X/Y/Z0-Z3 + экструдер настроены
  ✓ Термистор стола (NTC 100K B3950, PF3), показания корректны
  ✓ Нагрев стола 220V через MOC3063 (PA8), PID откалиброван
  ✓ Хотенд, PID откалиброван
  ✓ Датчик филамента (EBBCan:PB3)
  ✓ Вентиляторы (деталь PA0, хотенд PA1)
  ✓ force_move включён (движение без хоминга через SET_KINEMATIC_POSITION)
  ✓ Probe сконфигурирован на EBBCan:PB9 (ждёт физический датчик)

Что НЕ сделано:
  ✗ Z probe — нет физического датчика (PB9 пустой, ADXL345 не подходит)
  ✗ Хоминг XY не тестировался
  ✗ quad_gantry_level не настроен
  ✗ Z offset не откалиброван
  ✗ Input shaper (ADXL345) не настроен
  ✗ Калибровка экструдера не проверялась

========================================================================
ЖЕЛЕЗО
========================================================================

Raspberry Pi 4 (MainsailOS 6.12.62+rpt-rpi-2712)
  IP: 192.168.2.20  SSH: pi@192.168.2.20 (ключ без пароля)
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
  Встроен ADXL345 (пока не настроен, для input shaper в будущем)

CAN шина: 1 000 000 bps, терминаторы 120 Ом на обоих концах

========================================================================
СТРУКТУРА КОНФИГОВ
========================================================================

~/printer_data/config/
  printer.cfg     — главный файл (includes + MCU UUID + heater_bed + safe_z_home)
  core.cfg        — температурный сенсор Pi
  stepper.cfg     — все моторы X/Y/Z0-Z3
  ebb_can.cfg     — экструдер, вентиляторы, probe, датчик филамента
  debug.cfg       — force_move, макросы PROBE_STATE, TEST_HOME_X
  moonraker.conf  — конфиг Moonraker (не менялся)
  mainsail.cfg    — auto-managed Mainsail (не менять вручную)

========================================================================
КАК ВОССТАНОВИТЬ С НУЛЯ
========================================================================

ШАГ 1 — CAN интерфейс на Pi
-----------------------------
ssh pi@192.168.2.20
sudo nano /etc/network/interfaces.d/can0

Содержимое:
  allow-hotplug can0
  iface can0 can static
      bitrate 1000000
      up ip link set $IFACE txqueuelen 1024

sudo systemctl restart networking
Проверка: ip -details link show can0  → должен быть UP, bitrate 1000000


ШАГ 2 — Прошивка плат
-----------------------
Прошивки уже скомпилированы и лежат в configs/:
  klipper_octopus_f446_canbridge_20260206.bin   → Octopus
  klipper_ebb42_stm32g0b1_can_1m.bin            → EBB 42

Прошивка EBB 42 через DFU (если слетела):
  1. Подключить EBB 42 по USB к Pi
  2. Зажать BOOT0, нажать RESET, отпустить BOOT0
  3. lsusb | grep '0483:df11'  ← должно показать DFU device
  4. echo 'raspberry' | sudo -S dfu-util -a 0 \
       -D ~/klipper/out/klipper.bin \
       --dfuse-address 0x08000000:force:mass-erase:leave \
       -d 0483:df11

Прошивка Octopus: через SD карту или DFU (см. документацию BTT)


ШАГ 3 — Копирование конфигов
------------------------------
scp snapshot-2026-03-06/printer.cfg   pi@192.168.2.20:~/printer_data/config/
scp snapshot-2026-03-06/core.cfg      pi@192.168.2.20:~/printer_data/config/
scp snapshot-2026-03-06/stepper.cfg   pi@192.168.2.20:~/printer_data/config/
scp snapshot-2026-03-06/ebb_can.cfg   pi@192.168.2.20:~/printer_data/config/
scp snapshot-2026-03-06/debug.cfg     pi@192.168.2.20:~/printer_data/config/
scp snapshot-2026-03-06/moonraker.conf pi@192.168.2.20:~/printer_data/config/


ШАГ 4 — Перезапуск
--------------------
ssh pi@192.168.2.20 'curl -X POST http://localhost:7125/printer/restart'


ШАГ 5 — Проверка
------------------
Признаки нормальной работы в klippy.log:
  Loaded MCU 'mcu' 151 commands      ← Octopus OK
  Loaded MCU 'EBBCan' 138 commands   ← EBB 42 OK
  Configured MCU 'mcu' (1024 moves)
  Configured MCU 'EBBCan' (1024 moves)

Проверка температур:
  curl http://192.168.2.20:7125/printer/objects/query?heater_bed&extruder
  → heater_bed temp ~комнатная (20-25°C)
  → extruder temp ~комнатная (20-25°C)

Проверка CAN:
  ssh pi@192.168.2.20 'ip -details link show can0'
  → state UP, bitrate 1000000, bus_state=active

========================================================================
КЛЮЧЕВЫЕ ПАРАМЕТРЫ
========================================================================

MCU canbus UUID:
  Octopus: dde4eba60f0f
  EBBCan:  6269b37ddaba

PID стола (откалиброван при 60°C):
  pid_Kp: 57.369
  pid_Ki: 0.286
  pid_Kd: 2872.015

PID хотенда (откалиброван):
  pid_Kp: 29.581
  pid_Ki: 4.287
  pid_Kd: 51.028

Нагрев стола:
  Питание: 220V AC
  Управление: PA8 (FAN0 на Octopus) → MOC3063 оптопара → триак
  pwm_cycle_time: 0.02 (50 Гц)

Экструдер:
  rotation_distance: 5.44 (требует проверки/калибровки)
  Драйвер: TMC2209 @ 0.8A

Моторы X/Y/Z:
  Драйверы: TMC5160 @ 1.1A, sense_resistor: 0.075, spi1
  rotation_distance: 40
  Z gear_ratio: 80:20

========================================================================
СЛЕДУЮЩИЕ ШАГИ (после восстановления)
========================================================================

1. Установить физический датчик на PB9 (EBB 42) для Z probe
   → Подойдёт простой микровыключатель
   → Конфиг уже готов в ebb_can.cfg [probe]

2. Протестировать хоминг XY (G28 X Y)
   → Проверить направления движения

3. quad_gantry_level — добавить секцию в printer.cfg
   → Нужны 4 точки зондирования по углам стола

4. Откалибровать Z offset через PROBE_CALIBRATE

5. Настроить ADXL345 для input shaper:
   Пины на EBB 42 v1.2:
     cs_pin: EBBCan:PB12
     spi_software_sclk_pin: EBBCan:PB10
     spi_software_mosi_pin: EBBCan:PB11
     spi_software_miso_pin: EBBCan:PB14

6. Input shaper калибровка: SHAPER_CALIBRATE

========================================================================
ПОЛЕЗНЫЕ КОМАНДЫ
========================================================================

# Движение без хоминга (stol уже на Z=50 после ручного опускания)
SET_KINEMATIC_POSITION X=150 Y=150 Z=50
G91
G1 Z50 F300   # опустить ещё на 50мм
G90

# Состояние probe
QUERY_PROBE
PROBE_STATE    # кастомный макрос с текстовым выводом

# Перезапуск после shutdown
curl -X POST http://192.168.2.20:7125/printer/firmware_restart

# Проверить UUID на CAN шине (только CanBoot узлы)
ssh pi@192.168.2.20 'python3 ~/klipper/lib/canboot/flash_can.py -i can0 -q'
