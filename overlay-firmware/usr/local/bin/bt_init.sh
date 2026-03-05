#!/bin/bash

# Define the default Bluetooth parameter
DEFAULT_PARAM="aic"

# Function to determine the Bluetooth parameter
# If no parameter is provided, use the default value
determine_bt_param() {
	if [ $# -eq 0 ]; then
		local bt_param="$DEFAULT_PARAM"
		echo "No parameter provided, using default: $bt_param" >&2
		echo "$bt_param"
	else
		local bt_param="$1"
		echo "Using provided parameter: $bt_param" >&2
		echo "$bt_param"
	fi
}

# Function to verify if the kernel module is loaded when the parameter is "aic"
verify_kernel_module() {
	local param="$1"
	if [ "$param" = "aic" ]; then
		# Check if the aic8800_btlpm kernel module is loaded
		if ! lsmod | grep -q "aic8800_btlpm"; then
			echo "Error: aic8800_btlpm.ko not loaded" >&2
			exit 1
		fi
	fi
}

# Function to enable Bluetooth sleep mode
enable_bt_sleep_mode() {
	echo 1 > /proc/bluetooth/sleep/btwrite
}

# Function to disable Bluetooth sleep mode
disable_bt_sleep_mode() {
	echo 0 > /proc/bluetooth/sleep/btwrite
}

# Function to attach HCI to the appropriate UART device
attach_hci() {
	local param="$1"
	if [ -c /dev/ttyAS1 ]; then
		hciattach -n /dev/ttyAS1 "$param" &
	elif [ -c /dev/ttyS1 ]; then
		hciattach -n /dev/ttyS1 "$param" &
	else
		echo "Error: $param No suitable UART device found" >&2
		disable_bt_sleep_mode
		exit 1
	fi
}

# Determine the Bluetooth parameter
BT_PARAM=$(determine_bt_param "$@")

# Verify the kernel module
verify_kernel_module "$BT_PARAM"

# Enable Bluetooth sleep mode
enable_bt_sleep_mode

# Attach HCI to the appropriate UART device
attach_hci "$BT_PARAM"

exit 0