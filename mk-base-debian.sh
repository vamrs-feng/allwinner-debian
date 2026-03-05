#!/bin/bash -e

if [ ! $TARGET ]; then
	echo "---------------------------------------------------------"
	echo "please enter desktop type number:"
	echo "请输入要构建的桌面类型序号:"
	echo "[0] Exit Menu"
	echo "[1] xfce"
	echo "[2] lxde"
	echo "[3] gnome"
	echo "[4] lite"
	echo "[5] sunxibox"
	echo "---------------------------------------------------------"
	read input

	case $input in
		0)
			exit;;
		1)
			TARGET=xfce
			;;
		2)
			TARGET=lxde
			;;
		3)
			TARGET=gnome
			;;
		4)
			TARGET=lite
			;;
		5)
			TARGET=sunxibox
			;;
		*)
			echo 'input desktop type error, exit !'
			exit;;
	esac
fi

if [ ! $RELEASE ]; then
	echo "---------------------------------------------------------"
	echo "please enter debian version number:"
	echo "请输入要构建的debian版本序号:"
	echo "[0] Exit Menu"
	echo "[1] Debian 9(stretch)"
	echo "[2] Debian 10(buster)"
	echo "[3] Debian 11(bullseye)"
	echo "[4] Debian 12(bookworm)"
	echo "---------------------------------------------------------"
	read input

	case $input in
		0)
			exit;;
		1)
			RELEASE=stretch
			;;
		2)
			RELEASE=buster
			;;
		3)
			RELEASE=bullseye
			;;
		4)
			RELEASE=bookworm
			;;
		*)
			echo 'input debian version error, exit !'
			exit;;
	esac
fi

if [ ! $ARCH ]; then
	echo "---------------------------------------------------------"
	echo "please enter the ARCH number:"
	echo "请输入文件系统所要运行的体系架构序号:"
	echo "[0] Exit Menu"
	echo "[1] armhf"
	echo "[2] arm64"
	echo "---------------------------------------------------------"
	read input

	case $input in
		0)
			exit;;
		1)
			ARCH=armhf
			;;
		2)
			ARCH=arm64
			;;
		*)
			echo 'input ARCH error, exit !'
			exit;;
	esac
fi

if [ "$TARGET" == "lite" ]; then
	BUILD_VERSION='base'
	echo -e "\033[47;36m set TARGET=lite, use $RELEASE-base-$ARCH to build ...... \033[0m"
else
	BUILD_VERSION=$TARGET
fi

if [ -e linaro-$RELEASE-$TARGET-$ARCH-*.tar.gz ]; then
	rm linaro-$RELEASE-$TARGET-$ARCH-*.tar.gz
fi


cd debian-build-service/$RELEASE-$BUILD_VERSION-$ARCH

echo -e "\033[47;36m Staring Download...... \033[0m"

make clean

./configure

make

DATE=$(date +%Y%m%d)
if [ -e linaro-$RELEASE-*.tar.gz ]; then
	sudo chmod 0666 linaro-$RELEASE-*.tar.gz
	mv linaro-$RELEASE-*.tar.gz ../../linaro-$RELEASE-$TARGET-$ARCH-$DATE.tar.gz
	echo -e "\033[47;36m Finish building the filesystem! \033[0m"
else
	echo -e "\e[41;31m Failed to run livebuild, please check your network connection. \e[0m"
fi
