## 简介

A set of shell scripts that will build GNU/Linux distribution rootfs image for sunxi platform.

## 安装依赖

构建主机环境最低要求Ubuntu20.04及以上版本，推荐使用Ubuntu20.04

```
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## 构建 Debian11 镜像（目前只调试了64bit）

- lite：控制台版，无桌面
- xfce：桌面版，使用xfce4桌面套件
- lxde：桌面版，使用lxde桌面套件
- gnome：桌面版，使用gnome桌面套件


#### step1.构建基础 Debian 系统。

```shell
# 运行以下脚本，根据提示选择要构建的版本
./mk-base-debian.sh
```

#### step2(可选).基于基础 Debian系统进行联网二次定制 Debian系统(一般构建一次,建议自主定制)。

```
./mk-custome-rootfs.sh [./compressed_files/linaro-bullseye-xxx-arm64.tar.gz]
```

Note:::
1. 需要root权限，需要网络支持
2. 输出默认在debian/custome_roofs_def/
3. 建议重新打包生成tag.gz包，放到compressed_files目录下，再进行综合使用
:::

#### step3.添加 sunxi overlay 层，然后生成文件系统镜像

```shell
./mk-image.sh ./compressed_files/linaro-bullseye-xxx-arm64.tar.gz
```

Note:::
1. mk-image.sh 添加了对package的处理，依据对配置文件:./packages/arm64/allwinner-packages.xml的处理，部分package包将会在debian启动过程中进行安装
2. 大致逻辑：根据xml配置，将需要处理的package也就是根据芯片支持情况和优先级拷贝到Debian rootfs。启动过程中：allwinner.service 将会根据优先级进行安装。该部分可有厂商自主定制。
:::

