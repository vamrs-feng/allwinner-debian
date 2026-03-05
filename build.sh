##!/bin/bash

set -e

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
	echo -e "\033[47;30mINFO: $*\033[0m"
}

#eg. save_config "LICHEE_PLATFORM" "$LICHEE_PLATFORM" $BUILD_CONFIG
function save_config()
{
	local cfgkey=$1
	local cfgval=$2
	local cfgfile=$3
	local dir=$(dirname $cfgfile)

	[ ! -d $dir ] && mkdir -p $dir
	cfgval=$(echo -e "$cfgval" | sed -e 's/^\s\+//g' -e 's/\s\+$//g')

	if [ -f $cfgfile ] && [ -n "$(sed -n "/^\s*export\s\+$cfgkey\s*=/p" $cfgfile)" ]; then
		sed -i "s|^\s*export\s\+$cfgkey\s*=\s*.*$|export $cfgkey=$cfgval|g" $cfgfile
	else
		echo "$cfgkey=$cfgval cfgfile=$cfgfile"
		echo "export $cfgkey=$cfgval" >> $cfgfile
	fi
}

function do_select()
{
	local val_list=$(ls ${LICHEE_TOP_DIR}/debian/compressed_files/)
	local cnt=0
	local cfg_val=${DEBIAN_TAR_ROOTFS}
	local cfg_idx=0

	printf "All available rootfs files:\n"
	for val in ${val_list[@]}; do
		array[$cnt]=$val
		if [ "X_$cfg_val" == "X_${array[$cnt]}" ]; then
			cfg_idx=$cnt
		fi
		printf "%4d. %s\n" $cnt $val
		let cnt=cnt+1
	done
	while true; do
		read -p "Choice [${array[$cfg_idx]}]: " choice
		if [ -z "${choice}" ]; then
			choice=$cfg_idx
		fi

		if [ -z "${choice//[0-9]/}" ] ; then
			if [ $choice -ge 0 -a $choice -lt $cnt ] ; then
				cfg_val="${array[$choice]}"
				break;
			fi
		fi
		 printf "Invalid input ...\n"
	done

	if [ "x${DEBIAN_TAR_ROOTFS}" == "x" ]; then
		mk_info "first config, skip debian clean"
	elif [ "x${DEBIAN_TAR_ROOTFS}" != "x${cfg_val}" ]; then
		mk_warn "select diff rootfs: $DEBIAN_TAR_ROOTFS to ${cfg_val}, need to clean"
		clean
	fi

	#echo "cfg_val=${cfg_val}"
	echo "Setup debian config to ${BUILD_CONFIG} "
	save_config "DEBIAN_TAR_ROOTFS" ${cfg_val} ${BUILD_CONFIG}
}

function build_debian()
{
	local ROOTFS=${LICHEE_PLAT_OUT}/rootfs_def

	if [ "x" == "x${DEBIAN_TAR_ROOTFS}" ]; then
		mk_error "unkown debian rootfs select"
		mk_error "Please run ./build.sh config first in top dir or in debian dir"
		exit 1
	fi

	#rootfs_archive=`cat ${boardconfig} | grep -w "LICHEE_ROOTFS" | awk -F= '{printf $2}'`
	local rootfs_archive=${DEBIAN_TAR_ROOTFS}
	local rootfs_archivedir=${LICHEE_TOP_DIR}/debian/compressed_files/${rootfs_archive}

	#only support debian compressed file
	if [ ! -f ${rootfs_archivedir} ]; then
		mk_error "not find ${rootfs_archivedir}"
		exit 1
	fi

	echo "./mk-image.sh ${rootfs_archivedir}"
	./mk-image.sh ${rootfs_archivedir}

#	export PATH=$PATH:${LICHEE_BUILD_DIR}/bin
#	#fakeroot chown	 -h -R 0:0	${ROOTFS}
#
#	# 321 * 258048, about 79M, it should be enough for small capacity spinand
#	if [ -n "`echo $LICHEE_KERN_VER | grep "linux-[34].[149]"`" ] || [ "x${LICHEE_KERN_VER}" = "xlinux-5.4" ]; then
#		fakeroot mkfs.ubifs -m 4096 -e 258048 -c 375 -F -x zlib -r ${ROOTFS} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
#	else
#		fakeroot mkfs.ubifs -m 2048 -e 126976 -c 375 -F -x zlib -r ${ROOTFS} -o ${LICHEE_PLAT_OUT}/rootfs.ubifs
#	fi
#
#cat  > ${LICHEE_PLAT_OUT}/.rootfs << EOF
#chown -h -R 0:0 ${ROOTFS}
#${LICHEE_BUILD_DIR}/bin/makedevs -d \
#${LICHEE_DEVICE_DIR}/config/rootfs_tar/_device_table.txt ${ROOTFS}
#${LICHEE_BUILD_DIR}/bin/mksquashfs \
#${ROOTFS} ${LICHEE_PLAT_OUT}/rootfs.squashfs -root-owned -no-progress -comp xz -noappend
#EOF
#
#	chmod a+x ${LICHEE_PLAT_OUT}/.rootfs
#	fakeroot -- ${LICHEE_PLAT_OUT}/.rootfs
}

function clean()
{
	echo "debian cleaning ..."
	if [ -d "${LICHEE_PLAT_OUT}/rootfs_def" ]; then
		rm -rf ${LICHEE_PLAT_OUT}/rootfs_def
	fi
}

function main()
{
	if [ -f ../.buildconfig ]; then
		source ../.buildconfig
	else
		echo "Please run ./build.sh config first in top dir"
		return 1
	fi

	export BUILD_CONFIG=${LICHEE_TOP_DIR}/.buildconfig

	case "$1" in
		clean)
			clean
			;;
		config)
			do_select
			;;
		*)
			if [ "x${LICHEE_PLATFORM}" = "xlinux" ]; then
				build_debian
			fi
			;;
	esac

}

main $@
