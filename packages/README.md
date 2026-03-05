# Debian版本区分支持说明

## 1. 目录结构

为了支持不同Debian版本的deb包，建议按照以下目录结构组织：

```
debian/packages/
├── arm64/
│   ├── gst-plugins-ugly1.0/
│   │   ├── debian11/
│   │   │   └── gstreamer1.0-plugins-ugly_1.18.4-2+deb11u1_arm64.deb
│   │   └── debian13/
│   │       └── gstreamer1.0-plugins-ugly_1.26.3-4_arm64.deb
│   ├── gst-plugins-base1.0/
│   │   ├── debian11/
│   │   │   └── gstreamer1.0-plugins-base_1.18.4-2+deb11u3.1_arm64.deb
│   │   └── debian13/
│   │       └── gstreamer1.0-plugins-base_1.26.2-1_arm64.deb
│   ├── gst-plugins-good1.0/
│   │   ├── debian11/
│   │   │   └── gstreamer1.0-plugins-good_1.18.4-2+deb11u3.1_arm64.deb
│   │   └── debian13/
│   │       └── gstreamer1.0-plugins-good_1.26.2-1_arm64.deb
│   ├── gst-plugins-bad1.0/
│   │   ├── debian11/
│   │   │   └── gstreamer1.0-plugins-bad_1.18.4-3+deb11u5.1_arm64.deb
│   │   └── debian13/
│   │       └── gstreamer1.0-plugins-bad_1.26.2-3_arm64.deb
│   ├── gstreamer/
│   │   ├── debian11/
│   │   │   └── libgstreamer1.0-0_1.18.4-2.1+deb11u1_arm64.deb
│   │   └── debian13/
│   │       └── libgstreamer1.0-0_1.26.2-2_arm64.deb
│   ├── allwinner-packages.xml
│   └── ...
├── allwinner-packages.sh

```

## 2. XML配置文件语法

在`allwinner-packages.xml`中，可以使用以下语法指定包的Debian版本支持：

```xml
<!-- 支持所有Debian版本 -->
<package path="packages/arm64/chromium/all-versions" install="first-boot" priority="2" platform="common" debian="all" />

<!-- 仅支持Debian 11 -->
<package path="packages/arm64/gst-plugins-ugly1.0" install="first-boot" priority="4" name="gstreamer1.0-plugins-ugly_1.18.4-2+deb11u1_arm64.deb" platform="common" debian="11" />

<!-- 仅支持Debian 13 -->
<package path="packages/arm64/gst-plugins-ugly1.0" install="first-boot" priority="4" name="gstreamer1.0-plugins-ugly_1.26.3-4_arm64.deb" platform="common" debian="13" />

<!-- 支持Debian 11和13 -->
<package path="packages/arm64/chromium" install="first-boot" priority="2" platform="common" debian="11|13" />
```

## 3. 环境变量设置

### 3.1 手动设置

在编译时，可以通过设置`LICHEE_DEBIAN_VERSION`环境变量来指定目标Debian版本：

```bash
export LICHEE_DEBIAN_VERSION=13
./build.sh
```

### 3.2 自动配置

当前系统支持在配置编译时选择系统包是bullseye或者trixie来自动配置`DEBIAN_VERSION_ID`。当通过SDK的配置`./build.sh config`选择目标固件时，系统会自动检测对应固件的Debian版本，并设置相应的环境变量，无需手动指定。

## 4. 示例配置

### 4.1 为不同Debian版本指定不同的包

```xml
<!-- libcedarc packages -->
<package path="packages/arm64/libcedarc" install="first-boot" priority="2" name="libcedarc-dev_1.0.0_arm64.deb" platform="A523|A527|T527|T527V" debian="11" />
<package path="packages/arm64/libcedarc" install="first-boot" priority="2" name="libcedarc-dev_3.0.0_arm64.deb" platform="A523|A527|T527|T527V" debian="13" />

<!-- gstreamer packages -->
<package path="packages/arm64/gstreamer" install="first-boot" priority="4" name="libgstreamer1.0-0_1.18.4-2.1+deb11u1_arm64.deb" platform="common" debian="11" />
<package path="packages/arm64/gstreamer" install="first-boot" priority="4" name="libgstreamer1.0-0_1.26.2-2_arm64.deb" platform="common" debian="13" />

<!-- gst-plugins-ugly1.0 packages -->
<package path="packages/arm64/gst-plugins-ugly1.0" install="first-boot" priority="4" name="gstreamer1.0-plugins-ugly_1.18.4-2+deb11u1_arm64.deb" platform="common" debian="11" />
<package path="packages/arm64/gst-plugins-ugly1.0" install="first-boot" priority="4" name="gstreamer1.0-plugins-ugly_1.26.3-4_arm64.deb" platform="common" debian="13" />
```

### 4.2 共享包（支持所有Debian版本）

```xml
<!-- glmark2 packages (支持所有Debian版本) -->
<package path="packages/arm64/glmark2" install="first-boot" priority="5" name="glmark2-es2-drm_2023.01+dfsg-3_arm64.deb" platform="common" debian="all" />

<!-- gst-omx packages (支持所有Debian版本) -->
<package path="packages/arm64/gst-omx-generic1.0" install="first-boot" priority="4" name="gstreamer1.0-omx-allwinner_1.18.3-1.1_arm64.deb" platform="common" debian="all" />
```

## 5. 注意事项

1. 确保为不同Debian版本提供正确的依赖关系
2. 对于共享包，使用`debian="all"`属性
3. 对于特定版本的包，使用`debian="11"`或`debian="13"`属性
4. 建议为每个包版本创建单独的目录，以避免混淆

## 6. 兼容性

- 原有配置（未指定debian属性的包）默认支持所有Debian版本
- 新配置支持与旧配置共存
- 脚本会自动处理不同Debian版本的包选择