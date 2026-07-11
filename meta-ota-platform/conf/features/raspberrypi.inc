#
# Raspberry Pi 3 Model B+ configuration
#

# Target device tree
KERNEL_DEVICETREE = "broadcom/bcm2710-rpi-3-b-plus.dtb"

# Use systemd
INIT_MANAGER = "systemd"

# Bootloader
RPI_USE_U_BOOT = "1"

# Enable UART for serial console
ENABLE_UART = "1"
