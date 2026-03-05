#!/bin/bash -e

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

SDK_ROOT_PATH=`pwd`
SDK_OUT_PATH=${SDK_ROOT_PATH}/out
ROOTFSIMAGE=rootfs.ext4
TARGET_ROOTFS_DIR=${SDK_OUT_PATH}/binary

export TOOLS_OUT_PATH=${SDK_ROOT_PATH}/tools
export SDK_ROOT_PATH=${SDK_ROOT_PATH}
export TARGET_ROOTFS_DIR=${TARGET_ROOTFS_DIR}

export PATH=$PATH:$TOOLS_OUT_PATH
ARCH=

if [ -f ${SDK_ROOT_PATH}/../.buildconfig ];then
	source ${SDK_ROOT_PATH}/../.buildconfig
fi


PARTITION_FEX_LOCATION=${SDK_ROOT_PATH}/tools

# parse remaining arguments
arguments=$#
if [ $arguments -eq 0 ]; then
	mk_info "invalid param!"
	mk_info "USAGE: $0 your filesystem's path & name or cover"
	mk_info "example: ./mk-image.sh ./linaro-bullseye-xfce-arm64.tar.gz"
	mk_info "example: ./mk-image.sh cover; that means copy system files to rootfs dir"
	exit 1;
else
	mk_info "Build rootfs ..."
fi

function change_to_aw_dir()
{
	if [ ! -f ${SDK_ROOT_PATH}/../.buildconfig ];then
		mk_info "use default dir"
		return
	fi

	SDK_OUT_PATH=${LICHEE_PLAT_OUT}
	TARGET_ROOTFS_DIR=${LICHEE_PLAT_OUT}/rootfs_def
	PARTITION_FEX_LOCATION=${LICHEE_BOARD_CONFIG_DIR}/debian
	ARCH=${LICHEE_ARCH}
}

function copy_system_firmware()
{
	mk_info "Copy system: amp firmware ..."
	local BIN_PATH=""
	local amp_bin_list=(
		${LICHEE_CHIP_CONFIG_DIR}/\${BIN_PATH}/amp_dsp0.bin:$1/amp_dsp0.bin
		${LICHEE_CHIP_CONFIG_DIR}/\${BIN_PATH}/amp_dsp1.bin:$1/amp_dsp1.bin
		${LICHEE_CHIP_CONFIG_DIR}/\${BIN_PATH}/amp_rv0.bin:$1/amp_rv0.bin
	)

	mk_info "start copy system firmware to $1"

	mkdir -p $1

	set +e
	for d in ${LICHEE_POSSIBLE_BIN_PATH[@]}; do
		[ ! -d ${LICHEE_CHIP_CONFIG_DIR}/$d ] && continue
		BIN_PATH=$d
		for file in ${amp_bin_list[@]} ; do
			eval cp -v -rf $(echo $file | sed -e 's/:/ /g') 2>/dev/null
		done
	done
	set -e

	mk_info "copy system firmware to $1 ok ..."
}

function copy_file()
{
	local src_dir=$1
	local dst_dir=$2

	[ ! -d ${src_dir} ] && return 0
	local file_list=$(ls ${src_dir})

	set +e
	for file in ${file_list[@]}; do
		if [ -L ${dst_dir}/${file} ]; then
			# bin,lib,sbin maybe is soft link in rootfs, use this to avoid copy error
			#echo "cp -rf ${src_dir}/${file}/* ${dst_dir}/${file}"
			cp -rf ${src_dir}/${file}/* ${dst_dir}/${file}
		else
			#echo "cp -rf ${src_dir}/${file} ${dst_dir}"
			cp -rf ${src_dir}/${file} ${dst_dir}
		fi
	done
	set -e
}

function copy_system_file()
{
	mk_info "Copy system: kernel file ..."
	if [ ! -f ${SDK_ROOT_PATH}/../.buildconfig ];then
		mk_info "not SDK dir, return"
		return
	fi

	local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_def
	local ROOTFS_FIRWMARE_PATH=${ROOTFS}/lib/firmware
	local INODES=""
	local BLOCKS=""
	local install_libs=""
	local install_libs_common=""
	local boardconfig="${LICHEE_BOARDCONFIG_PATH}"
	local KERNEL_STAGING_DIR=$LICHEE_OUT_DIR/$LICHEE_IC/kernel/staging

	rm -rf ${ROOTFS}/lib/modules
	mkdir -p ${ROOTFS}/lib/modules
	cp -rf ${KERNEL_STAGING_DIR}/lib/modules/* \
		${ROOTFS}/lib/modules/

	if [ "x$PACK_STABILITY" = "xtrue" -a -d ${LICHEE_KERN_DIR}/tools/sunxi ];then
		cp -v ${LICHEE_KERN_DIR}/tools/sunxi/* ${ROOTFS}/bin
	fi

	mk_info "Copy system: kernel file ... ok"
	copy_system_firmware ${ROOTFS_FIRWMARE_PATH}

	(cd ${ROOTFS}; ln -fs bin/busybox init)
	#substitute_inittab ${ROOTFS}/etc/inittab
}

function copy_overlay_file()
{
	mk_info "Copy ${SDK_ROOT_PATH}/overlay ..."
	copy_file ${SDK_ROOT_PATH}/overlay ${TARGET_ROOTFS_DIR}
	mk_info "Copy ${SDK_ROOT_PATH}/overlay ... ok"
}

function copy_overlay_debug_file()
{
	mk_info "Copy ${SDK_ROOT_PATH}/overlay-debug ..."
	copy_file ${SDK_ROOT_PATH}/overlay-debug ${TARGET_ROOTFS_DIR}
	mk_info "Copy ${SDK_ROOT_PATH}/overlay-debug ... ok"
}

function copy_target_file()
{
	mk_info "Copy ${SDK_ROOT_PATH}/target ..."
	local target_common_dir=${LICHEE_TOP_DIR}/target/${LICHEE_IC}/debian/common
	local target_dir=${LICHEE_TOP_DIR}/target/${LICHEE_IC}/debian/${LICHEE_BOARD}

	copy_file ${target_common_dir}/overlay ${TARGET_ROOTFS_DIR}
	copy_file ${target_dir}/overlay ${TARGET_ROOTFS_DIR}

	#run target hook.sh
	if [ -f ${target_common_dir}/debian_hook.sh ]; then
		${target_common_dir}/debian_hook.sh
	fi
	if [ -f ${target_dir}/debian_hook.sh ]; then
		${target_dir}/debian_hook.sh
	fi
	mk_info "Copy ${SDK_ROOT_PATH}/target ... ok"
}

# wifi/br firmware
function copy_overlay_firmware_file()
{
	#TODO: firmware_list to select wifi firmware

	local target_default_pkg=${LICHEE_TOP_DIR}/target/${LICHEE_IC}/debian/${LICHEE_BOARD}/package.config

	if [ -f ${target_default_pkg} ]; then
		echo "using ${target_default_pkg}"
		source ${target_default_pkg}
	fi

	mk_info "Copy overlay-firmware file..."
	if [ -f "${SDK_ROOT_PATH}/overlay-firmware/firmware.sh" ]; then
		${SDK_ROOT_PATH}/overlay-firmware/firmware.sh ${firmware_list}
		mk_info "Copy overlay-firmware file... ok"
	else
		mk_warn "no copy overlay-firmware file, please check"
	fi
}

function install_packages_file()
{
	local pkg_dir=${SDK_ROOT_PATH}/packages/${ARCH}
	local tmp_dir=${SDK_ROOT_PATH}/tmp_pkg

	mk_info "Copy deb from packages/${ARCH}"
	if [ x"${ARCH}" = x"" ]; then
		mk_error "ARCH not set"
		return -1
	fi

	if [ ! -f ${SDK_ROOT_PATH}/../.buildconfig ];then
		mk_warn "not SDK dir, maybe you must do: ./build.sh config"
	fi

	if [ -f ${SDK_ROOT_PATH}/packages/allwinner-packages.sh ] ; then
		${SDK_ROOT_PATH}/packages/allwinner-packages.sh
		mk_info "Copy deb from packages/${ARCH}... ok"
	else
		mk_warn "no copy deb packages: ${SDK_ROOT_PATH}/packages/allwinner-packages.sh no exist"
	fi
}

function check_version()
{
	local debian_rootfs_dir=$1
	mk_info "check debian version begin"
	if [ -d $debian_rootfs_dir ]; then
		os_release_file=$(find "$debian_rootfs_dir" -type f -name "os-release" -print -quit)
		if [ -f "$os_release_file" ]; then
			DEBIAN_VERSION_CODENAME=$(grep -E '^VERSION_CODENAME=' "$os_release_file" | cut -d= -f2)
			DEBIAN_VERSION_ID=$(grep -E '^VERSION_ID=' "$os_release_file" | cut -d= -f2)

			export DEBIAN_VERSION_CODENAME=$DEBIAN_VERSION_CODENAME
			export DEBIAN_VERSION_ID=$DEBIAN_VERSION_ID

			echo "using DEBIAN_VERSION_CODENAME=$DEBIAN_VERSION_CODENAME"
			echo "using DEBIAN_VERSION_ID=$DEBIAN_VERSION_ID"
		else
			mk_error "$debian_rootfs_dir/os-release no exist, unkonw version, please check!!!"
			exit 1
		fi
	else
		mk_error "$debian_rootfs_dir no exist, please check!!!"
		exit 1
	fi

}
function build_rootfs()
{
	change_to_aw_dir
	mkdir -p ${SDK_OUT_PATH}

	if [ x"$1" != x"cover" ]; then
		mk_info "1. Unzip the compressed file..."
		if [ ! -d ${TARGET_ROOTFS_DIR} ]; then
			mkdir -p ${TARGET_ROOTFS_DIR}
			#after decompression debian.tar.gz, first dir is binary, strip it
			fakeroot tar -xpf $1 --strip-components=1 -C ${TARGET_ROOTFS_DIR}
		fi
	else
		mk_info "1. using exist rootfs: ${TARGET_ROOTFS_DIR}"
	fi

	check_version ${TARGET_ROOTFS_DIR}

	mk_info "2. Copy the ko and others that system need..."

	copy_system_file

	install_packages_file

	copy_overlay_file

	copy_overlay_debug_file

	copy_overlay_firmware_file

	copy_target_file

	mk_info "3. Prepare the rootfs img..."
	#Optimizing the logic
	PARTITION_FEX=${PARTITION_FEX_LOCATION}/sys_partition.fex
	echo "PARTITION_FEX:${PARTITION_FEX}"
	BLOCK_FEX_LINE=`awk "/rootfs.fex/{print NR}" $PARTITION_FEX |head -n1`
	BLOCK_FEX_STR=$(awk "NR==${BLOCK_FEX_LINE}-1 {print $NF}" $PARTITION_FEX)
	BLOCK_FEX_SIZE=$(echo $BLOCK_FEX_STR |  cut -d "=" -f 2)
	EXT4_SIZE=$(expr $BLOCK_FEX_SIZE \* 512)

	fakeroot chown	 -h -R 0:0	${TARGET_ROOTFS_DIR}
	make_ext4fs -s -l ${EXT4_SIZE} ${SDK_OUT_PATH}/${ROOTFSIMAGE} ${TARGET_ROOTFS_DIR}

	mk_info "===== Build the rootfs finish ====="
	mk_info "img path: ${SDK_OUT_PATH}/${ROOTFSIMAGE}"
}

build_rootfs $@
