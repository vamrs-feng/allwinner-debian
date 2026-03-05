#!/bin/bash

set -euo pipefail
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
INIT_LOG="/var/log/allwinner-init.log"

log_info()
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" | tee -a "$INIT_LOG"
}

log_error()
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$INIT_LOG"
}

log_warn()
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" | tee -a "$INIT_LOG"
}

# Read partitions parameter from /proc/cmdline
get_partitions_from_cmdline() {
    local cmdline_partitions=$(grep -o 'partitions=[^ ]*' /proc/cmdline | cut -d '=' -f 2)
    echo "$cmdline_partitions"
}

# Get device partition based on partition name
get_device_for_partition() {
    local target_partition="$1"
    local partitions_string="$2"

    # Split string using :
    IFS=':' read -ra PARTITIONS <<< "$partitions_string"

    for partition_info in "${PARTITIONS[@]}"; do
        # Split partition info, e.g. userdata@mmcblk0p6
        IFS='@' read -ra INFO <<< "$partition_info"
        local partition_name="${INFO[0]}"
        local device_part="${INFO[1]}"

        if [[ "$partition_name" == "$target_partition" ]]; then
            echo "$device_part"
            return 0
        fi
    done

    # Return empty if partition is not found
    echo ""
    return 1
}

# Mount specified partition
mount_partition() {
    local partition_name="$1"

    log_info "Starting mount script for $partition_name partition"

    # Get partition information
    local partitions_string=$(get_partitions_from_cmdline)

    if [[ -z "$partitions_string" ]]; then
        log_error "No partitions parameter found in /proc/cmdline"
        exit 1
    fi

    log_info "Partitions string from cmdline: $partitions_string"

    # Get device partition corresponding to the specified partition
    local partition_device=$(get_device_for_partition "$partition_name" "$partitions_string")

    if [[ -z "$partition_device" ]]; then
        log_error "No $partition_name partition found in partitions parameter"
        exit 1
    fi

    log_info "Found $partition_name device: $partition_device"

    # Construct device path
    local device_path="/dev/$partition_device"
    log_info "Device path: $device_path"

    # Create mount point
    log_info "Creating mount point /$partition_name"
    mkdir -p "/$partition_name"

    # Check if partition exists
    if [[ ! -b "$device_path" ]]; then
        log_error "Device $device_path does not exist"
        exit 1
    fi

    # Check if already mounted
    if mountpoint -q "/$partition_name"; then
        log_info "/$partition_name is already mounted"
        return 0
    fi

    # Check if partition has a valid ext4 filesystem
    if ! blkid -t TYPE=ext4 "$device_path" > /dev/null 2>&1; then
        log_info "Formatting $device_path as ext4"
        mkfs.ext4 -F -m 0 "$device_path"
    else
        log_info "Found existing ext4 filesystem on $device_path, skipping format"
    fi

    # Mount partition
    log_info "Mounting $device_path to /$partition_name"
    mount -t ext4 -o sync,data=journal "$device_path" "/$partition_name/"

    log_info "Successfully mounted $partition_name partition"
}

mount_partition "userdata"

