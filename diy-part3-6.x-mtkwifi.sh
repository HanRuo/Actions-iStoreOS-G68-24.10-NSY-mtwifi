#!/bin/bash
#===============================================
# Description: DIY script
# File name: diy-script.sh
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# 修改uhttpd配置文件，启用nginx
# sed -i "/.*uhttpd.*/d" .config
# sed -i '/.*\/etc\/init.d.*/d' package/network/services/uhttpd/Makefile
# sed -i '/.*.\/files\/uhttpd.init.*/d' package/network/services/uhttpd/Makefile
sed -i "s/:80/:81/g" package/network/services/uhttpd/files/uhttpd.config
sed -i "s/:443/:4443/g" package/network/services/uhttpd/files/uhttpd.config
cp -a $GITHUB_WORKSPACE/configfiles/etc/* package/base-files/files/etc/
# ls package/base-files/files/etc/


# 追加binder内核参数
echo "CONFIG_PSI=y
CONFIG_KPROBES=y" >> target/linux/rockchip/armv8/config-6.6


# 集成CPU性能跑分脚本
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64 package/base-files/files/bin/coremark-arm64
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64.sh package/base-files/files/bin/coremark.sh
chmod 755 package/base-files/files/bin/coremark-arm64
chmod 755 package/base-files/files/bin/coremark.sh


# iStoreOS-settings
git clone --depth=1 -b main https://github.com/xiaomeng9597/istoreos-settings package/default-settings


# 定时限速插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus



# 增加nsy_g68-plus
echo -e "\\ndefine Device/nsy_g68-plus
\$(call Device/Legacy/rk3568,\$(1))
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G68
  DEVICE_DTS := rk3568/rk3568-nsy-g68-plus
  DEVICE_PACKAGES += kmod-nvme kmod-ata-ahci-dwc kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8169
endef
TARGET_DEVICES += nsy_g68-plus" >> target/linux/rockchip/image/legacy.mk


# 复制 02_network 网络配置文件到 target/linux/rockchip/armv8/base-files/etc/board.d/ 目录下
rm -f target/linux/rockchip/armv8/base-files/etc/board.d/02_network
cp -f $GITHUB_WORKSPACE/configfiles/02_network target/linux/rockchip/armv8/base-files/etc/board.d/02_network


# 加入初始化交换机脚本
cp -f $GITHUB_WORKSPACE/configfiles/swconfig_install package/base-files/files/etc/init.d/swconfig_install
chmod 755 package/base-files/files/etc/init.d/swconfig_install


# 删除系统预留WiFi脚本，必须要删除
rm -f package/base-files/files/sbin/wifi
# 默认启用WiFi，系统开机后自动初始化无线功能，系统已加 “50-wifi-up” 脚本文件，这个地方注释掉
# cp -f $GITHUB_WORKSPACE/configfiles/g68_mtkwifi package/base-files/files/etc/init.d/g68_mtkwifi
# chmod 755 package/base-files/files/etc/init.d/g68_mtkwifi


# rtl8367b驱动资源包，暂时使用这样替换
wget https://github.com/xiaomeng9597/files/releases/download/files/rtl8367b.tar.gz
tar -xvf rtl8367b.tar.gz


# 复制dts设备树文件到指定目录下
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3588-orangepi-5-plus.dts target/linux/rockchip/dts/rk3588/rk3588-orangepi-5-plus.dts
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-nsy-g68-plus.dts target/linux/rockchip/dts/rk3568/rk3568-nsy-g68-plus.dts
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-vngpu.dtsi target/linux/rockchip/dts/rk3568/rk3568-vngpu.dtsi
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-vngpu-rk809.dtsi target/linux/rockchip/dts/rk3568/rk3568-vngpu-rk809.dtsi

# ==========================================================
# 强制开启 RK3568 电源管理及所有核心依赖驱动 (RK809 专用)
# ==========================================================

# 定义配置文件路径 (建议两个路径都写，确保万无一失)
KCONFIGS="target/linux/rockchip/config-6.6 target/linux/rockchip/armv8/config-6.6"

for KCONFIG in $KCONFIGS; do
    [ -f "$KCONFIG" ] || continue

    # 1. 清除旧的冲突配置 (防止存在 # CONFIG_xxx is not set 导致追加无效)
    sed -i '/CONFIG_REGMAP_I2C/d' $KCONFIG
    sed -i '/CONFIG_REGMAP_IRQ/d' $KCONFIG
    sed -i '/CONFIG_MFD_CORE/d' $KCONFIG
    sed -i '/CONFIG_MFD_RK808/d' $KCONFIG
    sed -i '/CONFIG_REGULATOR/d' $KCONFIG
    sed -i '/CONFIG_REGULATOR_RK808/d' $KCONFIG
    sed -i '/CONFIG_REGULATOR_FIXED_VOLTAGE/d' $KCONFIG
    sed -i '/CONFIG_I2C_RK3X/d' $KCONFIG

    # 2. 追加全套满血驱动参数
    echo "CONFIG_REGMAP_I2C=y" >> $KCONFIG
    echo "CONFIG_REGMAP_IRQ=y" >> $KCONFIG
    echo "CONFIG_MFD_CORE=y" >> $KCONFIG
    echo "CONFIG_MFD_RK808=y" >> $KCONFIG
    echo "CONFIG_REGULATOR=y" >> $KCONFIG
    echo "CONFIG_REGULATOR_FIXED_VOLTAGE=y" >> $KCONFIG
    echo "CONFIG_REGULATOR_RK808=y" >> $KCONFIG
    echo "CONFIG_I2C_RK3X=y" >> $KCONFIG
    
    # 3. 开启硬件监控（通常 RK809 驱动需要它来报告电压状态）
    echo "CONFIG_HWMON=y" >> $KCONFIG
done

# ==========================================================
