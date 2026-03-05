#!/bin/bash
# Octopus v1.1 F446 + EBB 42 v1.2 STM32G0B1 — Klipper CAN setup
# Raspberry Pi: pi@192.168.2.20

PI="pi@192.168.2.20"

# ============================================================
# ШАГ 1: Подключиться к Raspberry Pi
# ============================================================
# ssh pi@192.168.2.20

# ============================================================
# ШАГ 2: Собрать прошивку для EBB 42 v1.2 (STM32G0B1, CAN)
# ============================================================
ssh $PI "cd ~/klipper && make clean"

ssh $PI "cat > ~/klipper/.config << 'EOF'
CONFIG_LOW_LEVEL_OPTIONS=y
CONFIG_MACH_STM32=y
CONFIG_MACH_STM32G0B1=y
CONFIG_STM32_CLOCK_REF_8M=y
CONFIG_STM32_FLASH_START_0000=y
CONFIG_STM32_MMENU_CANBUS_PB0_PB1=y
CONFIG_CANBUS_FREQUENCY=1000000
EOF"

ssh $PI "cd ~/klipper && make olddefconfig && make -j4"

# ============================================================
# ШАГ 3: Перевести EBB 42 в DFU режим (физически)
#   - Подключить EBB 42 по USB к Raspberry Pi
#   - Зажать кнопку BOOT0, нажать RESET, отпустить BOOT0
# Или программно (если Klipper запущен):
#   - Через Mainsail/Fluidd: CALL_REMOTE_METHOD method=reboot_machine
#   - Через Klipper console: RESTART + удержание BOOT0 при подаче питания
# ============================================================

# Проверить что EBB в DFU режиме:
ssh $PI "lsusb | grep '0483:df11'"

# ============================================================
# ШАГ 4: Прошить EBB 42 через DFU
# ============================================================
ssh $PI "echo 'raspberry' | sudo -S dfu-util -a 0 \
  -D ~/klipper/out/klipper.bin \
  --dfuse-address 0x08000000:force:mass-erase:leave \
  -d 0483:df11"

# ============================================================
# ШАГ 5: Отключить USB кабель от EBB 42
# ============================================================

# ============================================================
# ШАГ 6: Перезапустить Klipper и проверить
# ============================================================
ssh $PI "echo 'raspberry' | sudo -S systemctl restart klipper"
sleep 10
ssh $PI "tail -20 ~/printer_data/logs/klippy.log | grep -E 'Loaded MCU|Configured MCU|error|Error'"

# ============================================================
# ШАГ 7: Проверочные команды
# ============================================================

# Статус CAN интерфейса
ssh $PI "ip -details link show can0"

# Статус Klipper
ssh $PI "echo 'raspberry' | sudo -S systemctl status klipper --no-pager"

# Хвост лога
ssh $PI "tail -30 ~/printer_data/logs/klippy.log"

# Поиск CAN узлов (только CanBoot-узлы, Klipper-узлы не показывает)
ssh $PI "python3 ~/klipper/lib/canboot/flash_can.py -i can0 -q"
