#!/bin/bash

set -euo pipefail
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

PACKAGE_AUTOINSTALL_DIR="/packages/first-boot"
PACKAGE_AUTOINSTALL_FAILED_DIR="/packages/first-boot-failed"
PRIORITY_SUBDIRS=("1" "2" "3" "4" "5")
PACKAGE_SELECT_DIR="/packages/select"
FIRST_BOOT_FLAG="/usr/local/first_boot_flag"
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

install_priority_dir()
{
	local dir_path="$1"
	local dir_level=$(basename "$dir_path")

	log_info "=== Start installing priority level $dir_level (dir: $dir_path) ==="

	# Tmply(20250930), will change in next version
	local xorg_pkgs=$(find "$dir_path" -maxdepth 1 -type f -iname "xserver-xorg*.deb" | head -n 1)
	if [ -n "${xorg_pkgs}" ]; then
		log_info "Found target xserver package: $(basename "${xorg_pkgs}")"
		log_info "Installing xserver with dpkg ..."
        dpkg -i --force-overwrite "${xorg_pkgs}" 2>&1 | tee -a "$INIT_LOG" || {
            log_error "dpkg install xserver-packages failed (level $dir_level)"
            log_info "Fixing dependencies for level $dir_level ..."
            #apt-get install -f -y || log_error "Dependency fix failed (level $dir_level)"
        }

        if [ -e "/etc/lightdm/lightdm.conf" ] && [ "$dir_level" = "1" ]; then
            log_info "Restarting lightdm (triggered by level 1 xserver install) ..."
            systemctl daemon-reload || log_warn "Failed to reload systemd units (lightdm)"
            systemctl restart lightdm.service || log_error "lightdm restart failed"
        fi
    fi

	local other_pkgs=$(find "$dir_path" -maxdepth 1 -type f -name "*.deb" ! -name "xserver-xorg*.deb")
	if [ -n "$other_pkgs" ]; then
		apt-get install -fy --allow-downgrades $other_pkgs || {
			log_error "apt-get install failed (level $dir_level)"
			set +e  # 单个目录失败不阻断后续优先级,备份失败内容
			mkdir -p ${PACKAGE_AUTOINSTALL_FAILED_DIR}
			mv $dir_path ${PACKAGE_AUTOINSTALL_FAILED_DIR}/
        }
        set -e
	else
        log_info "No other packages to install (level $dir_level)"
    fi

    log_info "=== Finished installing priority level $dir_level ===\n"
}

# first boot start, need to install packages
if [ ! -e "${FIRST_BOOT_FLAG}" ] ; then
	log_info "It's the first time booting."
	log_info "The rootfs will be configured."

	if [ -d "$PACKAGE_AUTOINSTALL_DIR" ] ; then
		for subdir in "${PRIORITY_SUBDIRS[@]}"; do
			full_path="${PACKAGE_AUTOINSTALL_DIR}/${subdir}"
            if [ -d "$full_path" ]; then
                install_priority_dir "$full_path"
            else
                log_info "Priority level $subdir dir not found ($full_path), skip"
            fi
        done
	else
		log_info "allwinner-packages dir not found: $PACKAGE_AUTOINSTALL_DIR, skip"
	fi

	log_info "First boot initialization finished, create flag file: $FIRST_BOOT_FLAG"
	touch /usr/local/first_boot_flag

	log_info "Clean up package dirs ..."
	rm -rf ${PACKAGE_AUTOINSTALL_DIR}
else
	log_info "It's not the first time booting, skip"
fi
