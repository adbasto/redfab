# redfab-claude — Конфигурация 3D принтера CoreXY

Кастомный 3D принтер CoreXY на базе Klipper.
Подробная документация: [CLAUDE.md](CLAUDE.md)

## Железо
- **Основная MCU**: BTT Octopus v1.1 (STM32F446) — CAN bridge
- **Тулхед**: BTT EBB 42 v1.2 (STM32G0B1) — по CAN 1 Mbps
- **Драйверы**: TMC5160 (X/Y/Z) + TMC2209 (экструдер)
- **Кинематика**: CoreXY, 300×300×350 мм, quad gantry

## Ссылки
- [BTT Octopus документация](https://github.com/bigtreetech/docs/blob/master/docs/Octopus.md)
- [BTT EBB 42 v1.2 схема](https://github.com/bigtreetech/EBB/tree/master/EBB%20CAN%20V1.1%20and%20V1.2)
- [Klipper docs](https://www.klipper3d.org/)
- [Mainsail UI](http://192.168.2.20)

## Быстрый старт
```bash
ssh pi@192.168.2.20          # подключение к Pi
http://192.168.2.20          # Mainsail веб-интерфейс
http://192.168.2.20:7125     # Moonraker API
```
