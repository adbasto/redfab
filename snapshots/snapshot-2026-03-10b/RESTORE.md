# Снапшот 2026-03-10b — XY хоминг работает, X=0 слева

## Статус
- G28 X работает: концевик PG6, X=0 у левого концевика ✓
- G28 Y работает: концевик PG9, Y=350 у заднего концевика ✓
- Z: физический концевик PG10, хоминг настроен, не тестировался

## Ключевые настройки

### stepper_x
- dir_pin: !PF12
- position_endstop: 0  (X=0 у левого концевика)
- position_max: 300
- homing_positive_dir: не задан (Klipper определяет автоматически)

### stepper_y
- dir_pin: !PG1
- position_endstop: 350  (Y=350 у заднего концевика)
- position_max: 350
- homing_positive_dir: true

### homing_override (macros.cfg)
- После G28 XY: X=0 (левый), Y=350 (задний)
- G28 Z едет сначала на X=9, Y=27 (под Z концевик)

## Восстановление
```bash
scp snapshots/snapshot-2026-03-10b/*.cfg pi@192.168.2.20:~/printer_data/config/
scp snapshots/snapshot-2026-03-10b/moonraker.conf pi@192.168.2.20:~/printer_data/config/
# Затем FIRMWARE_RESTART через Mainsail
```
