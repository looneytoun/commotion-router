#!/bin/sh

svn co -r 31639 svn://svn.openwrt.org/openwrt/trunk openwrt || exit 1

cd openwrt

[ ! -e feeds.conf ] && cp -v ../feeds.conf feeds.conf
[ ! -e files ] && mkdir files
[ ! -e dl ] && mkdir ../dl && ln -sf ../dl dl
cp -rf -v ../default-files/* files/
if ! grep -q commotion feeds.conf; then
    echo "adding commotion package feed..."
    echo "src-link commotion ../../commotionfeed" >> feeds.conf
fi

scripts/feeds update -a
scripts/feeds install -a
for i in $(ls ../commotionfeed/); do scripts/feeds install $i; done

# Copy in Commotion-specific patches
cp -v ../patches/910-fix-out-of-bounds-index.patch feeds/packages/utils/collectd/patches/
cp -v ../patches/890_ath9k_advertize_beacon_int_infra_match.patch package/mac80211/patches
cp -v ../patches/891_ath9k_htc_advertize_allowed_vif_combinations.patch package/mac80211/patches
cp -v ../patches/892_ath9k_htc_remove_interface_combination_specific_checks.patch package/mac80211/patches
cp -v ../config .config

# Remove outdated patch
    echo "Removing outdated AR933X_WMAC_reset_code patch ..."
patch -p0 < ../patches/delete_AR933X_WMAC_reset_code.patch

# Backport compat-wireless-2012-09-07
if ! grep -q 2012-09-07 package/mac80211/Makefile; then
    echo "backporting compat-wireless-2012-09-07 drivers..."
    patch -p0 < ../patches/backport_compat_wireless_09-07-12.patch
fi

# Backport kernel 3.3.8
if ! grep -q 3.3.8 include/kernel-version.mk; then
    echo "backporting kernel v3.3.8..."
    patch -p0 < ../patches/backport_kernel_3.3.8.patch
fi

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Commotion OpenWrt is prepared. To build the firmware, type:"
echo " cd openwrt"
echo " make menuconfig #If you wish to add or change packages."
echo " make V=99"
