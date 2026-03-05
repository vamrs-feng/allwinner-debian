#!/bin/bash

set -e

WIFI_FIRMWARE_DIR=${SDK_ROOT_PATH}/overlay-firmware/wifi-firmware
TARGET_ROOTFS_FIRMWARE_DIR=${TARGET_ROOTFS_DIR}/lib/firmware

function mk_error()
{
	echo -e "\033[47;31mERROR: $*\033[0m"
}

function mk_warn()
{
	echo -e "\033[47;34mWARN: $*\033[0m"
}

function mk_info()
{
	echo -e "\033[47;32mINFO: $*\033[0m"
}

function copy_overlay_file()
{
	local src_dir=$1
	local dst_dir=$2

	[ ! -d ${src_dir} ] && return 0
	local file_list=$(ls ${src_dir})

	set +e
	for file in ${file_list[@]}; do
		if [ "x${file}" = "xwifi-firmware" -o "x${file}" = "xfirmware.sh" ] ; then
			continue
		fi

		if [ -L ${dst_dir}/${file} ]; then
			# bin,lib,sbin maybe is soft link in rootfs, use this to avoid copy error
			echo "cp -rf ${src_dir}/${file}/* ${dst_dir}/${file}"
			cp -rf ${src_dir}/${file}/* ${dst_dir}/${file}
		else
			echo "cp -rf ${src_dir}/${file} ${dst_dir}"
			cp -rf ${src_dir}/${file} ${dst_dir}
		fi
	done
	set -e
}

function copy_ovarlay_firmware_system()
{
	copy_overlay_file ${SDK_ROOT_PATH}/overlay-firmware ${TARGET_ROOTFS_DIR}
}

function copy_wifi_firmware() {
    local wifi_firmware_list=("$@")
    local package_wifi_firmware=""
    local default_firmware="PACKAGE_AIC8800_SDIO_FIRMWARE"

    echo "start copy wifi-firmware"

    if [ ${#wifi_firmware_list[@]} -eq 0 ]; then
        mk_warn "not set wifi-firmware, use default: $default_firmware"
        package_wifi_firmware="$default_firmware"
        cp -rf "${WIFI_FIRMWARE_DIR}/aic8800/sdio/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
        return
    fi

    echo "wifi_firmware_list:"
	echo ${wifi_firmware_list[@]} | sed 's/ /\n/g'

    for item in "${wifi_firmware_list[@]}"; do
        if [[ "$item" == *=* ]]; then
            package_wifi_firmware="${item#*=}"
        else
            package_wifi_firmware="$item"
        fi

        if [ -z "$package_wifi_firmware" ]; then
            echo "empty wifi-firmware, used default: $default_firmware"
            package_wifi_firmware="$default_firmware"
        fi

        echo "Copy wifi-firmware: $package_wifi_firmware"

        case "$package_wifi_firmware" in
            PACKAGE_AIC8800_SDIO_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/aic8800/sdio/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_AIC8800_USB_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/aic8800/usb/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_RTL8723DS_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/rtl8723ds/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_RTL8733BS_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/rtl8733bs/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_RTL8821CS_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/rtl8721cs/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_SSV6158_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/ssv6158/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_XR819_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/xr819/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_XR819A_FIRMWARE)
                cp -rf "${WIFI_FIRMWARE_DIR}/xr819a/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_XR819S_24M_FIRMWARE)
                find "${WIFI_FIRMWARE_DIR}/xr819s/" -maxdepth 1 -type f -exec cp -f {} "${TARGET_ROOTFS_FIRMWARE_DIR}" \;
                cp -rf "${WIFI_FIRMWARE_DIR}/xr819s/24M/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_XR819S_40M_FIRMWARE)
                find "${WIFI_FIRMWARE_DIR}/xr819s/" -maxdepth 1 -type f -exec cp -f {} "${TARGET_ROOTFS_FIRMWARE_DIR}" \;
                cp -rf "${WIFI_FIRMWARE_DIR}/xr819s/40M/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_XR829_24M_FIRMWARE)
                find "${WIFI_FIRMWARE_DIR}/xr829/" -maxdepth 1 -type f -exec cp -f {} "${TARGET_ROOTFS_FIRMWARE_DIR}" \;
                cp -rf "${WIFI_FIRMWARE_DIR}/xr829/24M/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            PACKAGE_XR829_40M_FIRMWARE)
                find "${WIFI_FIRMWARE_DIR}/xr829/" -maxdepth 1 -type f -exec cp -f {} "${TARGET_ROOTFS_FIRMWARE_DIR}" \;
                cp -rf "${WIFI_FIRMWARE_DIR}/xr829/40M/"* "${TARGET_ROOTFS_FIRMWARE_DIR}"
                ;;
            *)
                echo "Unknown firmware package: $package_wifi_firmware"
                ;;
        esac
    done
}

copy_wifi_firmware "$@"

copy_ovarlay_firmware_system
