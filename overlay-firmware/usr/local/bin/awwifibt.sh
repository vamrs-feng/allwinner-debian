#!/bin/bash

# WiFi/BT module loader
# Define the directory where kernel modules are located
MODULE_DIR="/lib/modules/$(uname -r)/"
# Define the path to the Bluetooth initialization script
BT_INIT_SCRIPT="/usr/local/bin/bt_init.sh"
# Define the default parameter for wireless module loading
DEFAULT_PARAM="aic"

# Function to determine the wireless parameter
# If no parameter is provided, use the default one
get_wireless_param() {
	if [ $# -eq 0 ]; then
		local param="$DEFAULT_PARAM"
		echo "No parameter provided, using default: $param" >&2
		echo "$param"
	else
		local param="$1"
		echo "Using provided parameter: $param" >&2
		echo "$param"
	fi
}

# Function to load kernel modules
load_kernel_modules() {
	local modules=("$@")
	echo "Starting WiFi/BT initialization..." >&2

	for module in "${modules[@]}"; do
		echo "Loading $module" >&2

		# Check if the module is already loaded
		if lsmod | grep -q "${module%.ko}"; then
			echo "$module is already loaded" >&2
		else
			if ! insmod "${MODULE_DIR}${module}"; then
				echo "Failed to load $module" >&2
				exit 1
			fi
		fi

		# Add extra delay after loading aic8800_fdrv.ko
		if [ "$module" = "aic8800_fdrv.ko" ]; then
			sleep 3
		else
			sleep 1
		fi
	done
}

# Function to execute the Bluetooth initialization script
execute_bt_init_script() {
	local script_path="$1"
	local param="$2"
	chmod +x "$script_path"
	echo "Executing $script_path with parameter $param" >&2
	"$script_path" "$param"
}

# Get the wireless parameter
WIRELESS_PARAM=$(get_wireless_param "$@")

# Only process when the parameter is "aic"
if [ "$WIRELESS_PARAM" = "aic" ]; then
	# Define the list of kernel modules to load
	MODULES=(
		"aic8800_bsp.ko"
		"aic8800_fdrv.ko"
		"aic8800_btlpm.ko"
	)

	# Load kernel modules
	load_kernel_modules "${MODULES[@]}"

	# Execute the Bluetooth initialization script
	execute_bt_init_script "$BT_INIT_SCRIPT" "$WIRELESS_PARAM"
fi