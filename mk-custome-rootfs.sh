#!/bin/bash -e

ROOT_PATH=`pwd`
DATE_NAME=$(date "+%Y%m%d")

CUSTOMER_ROOTFS_DIR=$ROOT_PATH/customer_rootfs_def
CUSTOMER_BASE_ROOTFS_TAR=$1
CUSTOMER_OUTPUT_ROOTFS_TAR_NAME=$DATE_NAME-$1

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

function help_info()
{
	mk_info "Usage: ./mk-custome-rootfs.sh [customer base rootfs tar gz file]"
	mk_info "Example: ./mk-custome-rootfs.sh compressed_files/linaro-bullseye-xfce-arm64.tar.gz"
    mk_info "Output dir: ${CUSTOMER_ROOTFS_DIR}"
    mk_info "Read first: debian/readme.md"
}

if [ "x${CUSTOMER_BASE_ROOTFS_TAR}" = "x" ] ; then
    mk_error "no customer roofs tar file input..."
    help_info
    exit 1
fi

ARCH=arm64

check_root()
{
    sudo umount ${CUSTOMER_ROOTFS_DIR}/dev
    exit -1
}

trap check_root ERR

sudo rm -rf $CUSTOMER_ROOTFS_DIR

if [ ! -d ${CUSTOMER_ROOTFS_DIR} ] ; then
    sudo mkdir -p ${CUSTOMER_ROOTFS_DIR}
fi

mk_info "------Building for Customer rootfs base on ${CUSTOMER_BASE_ROOTFS_TAR}------"

sudo tar -xpf ${CUSTOMER_BASE_ROOTFS_TAR} --strip-components=1 -C ${CUSTOMER_ROOTFS_DIR}

mk_info "------Copy overlay file------"
sudo cp -rf overlay/* ${CUSTOMER_ROOTFS_DIR}/

mk_info "------Copy overlay-debug file------"
sudo cp -rf overlay-debug/* ${CUSTOMER_ROOTFS_DIR}/

mk_info "------Copy overlay-firmware file------"
sudo cp -rf overlay-firmware/* ${CUSTOMER_ROOTFS_DIR}/

mk_info "------Copy Packages to install------"
sudo mkdir -p ${CUSTOMER_ROOTFS_DIR}/packages
sudo cp -rf packages/$ARCH/* ${CUSTOMER_ROOTFS_DIR}/packages

mk_info "------Copy allwinner target file, you must select------"
#sudo cp -rf ../target/[platform]/debian/[board]/overlay/* ${CUSTOMER_ROOTFS_DIR}/

# for T527, other platform, please change
#sudo cp ../target/common/overlay/* ${CUSTOMER_ROOTFS_DIR}/
#sudo cp ../target/t527/debian/pro3_linux_aiot/overlay/* ${CUSTOMER_ROOTFS_DIR}/

sudo mount -o bind /dev ${CUSTOMER_ROOTFS_DIR}/dev

cat << EOF | sudo chroot ${CUSTOMER_ROOTFS_DIR}

echo -e "\033[47;34mWARN: Maybe You Must Change By Yourself......\033[0m"
echo "nameserver 127.0.0.53" >> /etc/resolv.conf
echo "options edns0 trust-ad" >> /etc/resolv.conf

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

export APT_INSTALL="apt-get install -fy --allow-downgrades"

# ------regular enUS.UTF-8 fonts------
echo -e "\033[47;32mINFO: Regular en_US.UTF-8 fonts.......\033[0m"
# Uncomment en_US.UTF-8 for inclusion in generation

sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/^LANG=.*$/LANG=en_US.UTF-8/' /etc/default/locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale

# Generate locale
locale-gen

# Export env vars
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc

source ~/.bashrc

apt-get update
apt-get upgrade -y

apt-get remove -fy firefox-esr chromium*

# ------install gstreamer------
echo -e "\033[47;32mINFO: Setup Video.........\033[0m"
\${APT_INSTALL} gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-pulseaudio gstreamer1.0-gl libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev

\${APT_INSTALL} /packages/gstreamer/*.deb
\${APT_INSTALL} /packages/gst-plugins-base1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-bad1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-good1.0/*.deb
\${APT_INSTALL} /packages/gst-plugins-ugly1.0/*.deb
\${APT_INSTALL} /packages/gst-omx-generic1.0/*.deb


# ------install chromium------
echo -e "\033[47;32mINFO: Setup chromium.........\033[0m"
\${APT_INSTALL} /packages/chromium/*.deb

# ------install libcedarc -------
echo -e "\033[47;32mINFO: Setup libcedarc, you must select.........\033[0m"
# for A523/A527/T527
#\${APT_INSTALL} /packages/libcedarc/libcedarc-dev_1.0.0_arm64.deb
# for A733/T736
#\${APT_INSTALL} /packages/libcedarc/libcedarc-dev_2.0.0_arm64.deb

# ------install npu ------
echo -e "\033[47;32mINFO: Setup npu, you must select.........\033[0m"
# for T527
#\${APT_INSTALL} /packages/npu/npu-runtime_1.13.0_arm64.deb
# for A733/T736
#\${APT_INSTALL} /packages/npu/npu-runtime_2.0.3_arm64.deb

# -----install dpdk ------
echo -e "\033[47;32mINFO: Setup dpdk, you must select.........\033[0m"
#\${APT_INSTALL} /packages/ethernet/*.deb

# ------install allwinner isp ------
echo -e "\033[47;32mINFO: Setup isp, you must select.........\033[0m"
# for A523/A527/T527
#\${APT_INSTALL} /packages/libAWIspApi/libAWIspApi_601_1.0.0_arm64.deb
# for A733/T736
#\${APT_INSTALL} /packages/libAWIspApi/libAWIspApi_602_1.0.0_arm64.deb
# for A537/A333/T537
#\${APT_INSTALL} /packages/libAWIspApi/libAWIspApi_606_1.0.0_arm64.deb

# ------install xserver ------
echo -e "\033[47;32mINFO: Setup xserver, you must select.........\033[0m"
# for A523/A527/T527
#\${APT_INSTALL} /packages/xserver/xserver-xorg-mesa-g57_1.21.1-2_arm64.deb
# for A733/T736
#\${APT_INSTALL} /packages/xserver/xserver-xorg-img-bxm_1.21.1-2_arm64.deb


# ------install wifi/bt firmware-------
echo -e "\033[47;32mINFO: Setup wifi/bt, you must select.........\033[0m"
# for aic8800 sdio. other wifi need to change
#mkdir -p /lib/firmware/
#cp /wifi-firmware/aic8800/sdio/* /lib/firmware/

# -------install Chinese fonts------
echo -e "\033[47;32mINFO: Setup Chinese fonts.........\033[0m"
\${APT_INSTALL} fonts-wqy-zenhei fonts-aenigma
\${APT_INSTALL} xfonts-intl-chinese

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages

EOF

sudo umount ${CUSTOMER_ROOTFS_DIR}/dev

#sudo tar -zcpf ${CUSTOMER_OUTPUT_ROOTFS_TAR_NAME}.tar.gz ${CUSTOMER_ROOTFS_DIR}/

