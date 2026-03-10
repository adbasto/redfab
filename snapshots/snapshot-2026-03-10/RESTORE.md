# Снапшот 2026-03-10

## Статус на момент снапшота
- Klipper работает, обе MCU подключены по CAN
- Нагрев стола 220V через MOC3063/PA8 → PID откалиброван
- ADXL345 работает (INPUT_SHAPER готов к калибровке)
- Probe сконфигурирован на PB8 — физический датчик ещё не установлен
- Исследовано: ADXL345 как Z probe невозможно без пайки INT1

## Что ещё не сделано
- [ ] Установить микровыключатель на PB8 (Z probe)
- [ ] Первый хоминг XY
- [ ] quad_gantry_level
- [ ] Z offset калибровка (PROBE_CALIBRATE)
- [ ] Input shaper (SHAPER_CALIBRATE)
- [ ] Откалибровать экструдер (rotation_distance)
- [ ] PID экструдера (PID_CALIBRATE HEATER=extruder)

## Восстановление конфигов на Pi

```bash
# Скопировать конфиги на Pi
scp printer.cfg core.cfg stepper.cfg ebb_can.cfg debug.cfg pi@192.168.2.20:~/printer_data/config/
scp moonraker.conf pi@192.168.2.20:~/printer_data/config/

# Перезапустить Klipper
ssh pi@192.168.2.20 'sudo systemctl restart klipper'
```

## Прошивки
- Octopus F446: `firmware/klipper_octopus_f446_canbridge_20260206.bin` (CAN bridge, 1 Mbps)
- EBB 42 v1.2: `firmware/klipper_ebb42_stm32g0b1_can_1m.bin`

## Ключевые UUID
- Octopus (main MCU): `dde4eba60f0f`
- EBBCan (toolhead): `6269b37ddaba`
