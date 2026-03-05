#!/bin/bash

current_dir=`pwd`


#XML_FILE="$current_dir/arm64/allwinner-packages.xml"

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

XML_BOARD_FILE="${LICHEE_TOP_DIR}/target/${LICHEE_IC}/${LICHEE_LINUX_DEV}/${LICHEE_BOARD}/allwinner-packages.xml"
XML_PLATFORM_FILE="${LICHEE_TOP_DIR}/target/${LICHEE_IC}/${LICHEE_LINUX_DEV}/allwinner-packages.xml"
XML_DEFAULT_FILE="${SDK_ROOT_PATH}/packages/${LICHEE_ARCH}/allwinner-packages.xml"

XML_FILE=""

if [ -f ${XML_BOARD_FILE} ] ; then
	XML_FILE=${XML_BOARD_FILE}
elif [ -f ${XML_PLATFORM_FILE} ] ; then
	XML_FILE=${XML_PLATFORM_FILE}
elif [ -f ${XML_DEFAULT_FILE} ] ; then
	XML_FILE=${XML_DEFAULT_FILE}
else
	mk_error "${XML_BOARD_FILE} ${XML_PLATFORM_FILE} ${XML_DEFAULT_FILE}, all no exsit, please check"
	exit 1
fi

mk_info "copy packages by ${XML_FILE}"

function select_packages_from_xml()
{
	local target_platform=$1
	local dest_dir=$2

	# Get debian version from environment variables in order of priority:
	# 1. DEBIAN_VERSION_ID (from mk-image.sh, extracted from rootfs)
	# 2. LICHEE_DEBIAN_VERSION (legacy environment variable)
	# 3. Default to 11
	local debian_version=${DEBIAN_VERSION_ID:-${LICHEE_DEBIAN_VERSION:-11}}
	# Remove quotes from debian_version if present
	debian_version=$(echo "$debian_version" | tr -d '"')

	# Default to debian11 if not specified
	if [ -z "$debian_version" ]; then
		mk_warn "Debian version not specified, using default: debian11"
		debian_version="11"
	fi

	grep -o '<package [^>]*>' "$XML_FILE" | while read -r line; do
		path=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
		install=$(echo "$line" | sed -n 's/.*install="\([^"]*\)".*/\1/p')
		name=$(echo "$line" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
		priority=$(echo "$line" | sed -n 's/.*priority="\([^"]*\)".*/\1/p')
		platform=$(echo "$line" | sed -n 's/.*platform="\([^"]*\)".*/\1/p')
		debian=$(echo "$line" | sed -n 's/.*debian="\([^"]*\)".*/\1/p')

		copy_action=0

		# Check platform compatibility
		if [ "$platform" = "common" ]; then
			copy_action=1
		elif echo "$platform" | grep -qi "$target_platform"; then
			copy_action=1
			platform=${target_platform}
		fi

		# Check debian version compatibility
		if [ $copy_action -eq 1 ]; then
			if [ -z "$debian" ]; then
				# No debian specified, default to all versions
				copy_action=1
			elif [ "$debian" = "all" ]; then
				# All versions supported
				copy_action=1
			elif echo "$debian" | grep -qi "$debian_version"; then
				# Current debian version is supported
				copy_action=1
			else
				# Current debian version is not supported
				copy_action=0
			fi
		fi

		# Adjust path based on debian version
		if [ $copy_action -eq 1 ] && [ -n "$debian_version" ]; then
			# Check if there's a debian-specific subdirectory
			if [ -d "${SDK_ROOT_PATH}/${path}/debian${debian_version}" ]; then
				real_path=${SDK_ROOT_PATH}/${path}/debian${debian_version}
			else
				real_path=${SDK_ROOT_PATH}/${path}
			fi
		else
			real_path=${SDK_ROOT_PATH}/${path}
		fi

		real_name=${real_path}/${name}
		real_dest_dir=${dest_dir}/packages
		real_temp_dir=${dest_dir}/packages

		if [ "x$install" == "xfirst-boot" ] ; then
			real_temp_dir=${dest_dir}/packages/first-boot
			if [ "x$priority" == "x" ] ; then
				echo "no set priority, using default:3"
				priority=3	#default priority
			fi

			real_dest_dir=${real_temp_dir}/${priority}

		elif [ "x$install" == "xselect" -o "x$install" == "x" ] ; then
			real_dest_dir=${dest_dir}/packages/select
		elif [ "x$install" == "xpreinstall" ] ; then
			copy_action=0
		fi

		if [ $copy_action -eq 0 ]; then
			continue
		fi

		if [ -n "$name" ]; then
			mk_info "deb-name: ${real_name} platform:$platform"

			real_src_file=${real_name}

			if [ ! -f "$real_src_file" ]; then
				mk_warn "$real_src_file no exsit, skip"
				continue
			fi

			mkdir -p ${real_dest_dir}
			cp "${real_src_file}" "${real_dest_dir}/"
			echo "copy $real_src_file to $real_dest_dir"
		else
			mk_info "deb-dir: ${real_path} platform:$platform"

			if [ ! -d "$real_path" ]; then
				mk_warn "$real_path no exsit, skip"
				continue
			fi

			mkdir -p ${real_dest_dir}
			cp -rf "${real_path}"/* "${real_dest_dir}/"
			echo "copy ${real_path} ${real_dest_dir}/"
		fi
	done
}

mk_info "Need to delete old packages before build again!!!"
test -d ${TARGET_ROOTFS_DIR}/packages && rm -rf ${TARGET_ROOTFS_DIR}/packages

select_packages_from_xml ${LICHEE_IC} ${TARGET_ROOTFS_DIR}
