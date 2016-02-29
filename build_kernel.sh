#!/bin/bash
# kernel build script by thehacker911

KERNEL_DIR=$(pwd)
BUILD_USER="$USER"
TOOLCHAIN_DIR=/home/$BUILD_USER/android/toolchains
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
BUILD_WHERE=$(pwd)
BUILD_KERNEL_DIR=$BUILD_WHERE
BOARD_KERNEL_PAGESIZE=2048
BOOTIMG=$BUILD_KERNEL_DIR/build_image/boot.img
BOOTIMG_DIR=build_image/boot
BOOTIMG_DIR_2=build_image
DTBTOOL=$BUILD_KERNEL_DIR/tools/dtbtool
FLASH_ZIP_FILES=zip_files
FLASH_ZIP_DIR=$FLASH_ZIP_FILES/$KERNEL_NAME
KERNEL_ZIMG=$BUILD_KERNEL_DIR/arch/arm64/boot/Image
OUTPUT_DIR=$BUILD_KERNEL_DIR/build_image/output_kernel
ZIP_VER=`sed -n '8p' thehacker911`
DEVICE_VER=`sed -n '4p' thehacker911`
VER=`sed -n '6p' thehacker911`
VERWSM=`sed -n '10p' thehacker911`
SU_VER=`sed -n '14p' thehacker911`
KERNEL_NAME="$ZIP_VER$DEVICE_VER$VER"
KERNEL_NAME_WSM="$ZIP_VER$DEVICE_VER$VERWSM"
TOOLCHAIN=`sed -n '12p' thehacker911`
BUILD_CROSS_COMPILE=$TOOLCHAIN_DIR/$TOOLCHAIN
KERNEL_DEFCONFIG=hacker_defconfig
BASE_VER=`sed -n '2p' thehacker911`
DEVICE_VER=`sed -n '4p' thehacker911`
VER=`sed -n '6p' thehacker911`
HACKER_VER="$BASE_VER$DEVICE_VER$VER"
HACKER_VERWSM="$BASE_VER$DEVICE_VER$VERWSM"
DT_G920F=dt-g920f.img
DT_G925F=dt-g925f.img
KERNEL_CONFIG=`cat $KERNEL_DIR/build/config/base_defconfig`
BI_DIR=$KERNEL_DIR/build_image
CONFIG_DIR=arch/arm64/configs
CONFIG=hacker_defconfig
CONFIG_G920F=exynos7420-zeroflte_defconfig
CONFIG_G925F=exynos7420-zerolte_defconfig
DEVICE_VER_G920F=`sed -n '17p' thehacker911`
DEVICE_VER_G925F=`sed -n '18p' thehacker911`
HACKER_VER_920F="$BASE_VER$DEVICE_VER_G920F$VER"
HACKER_VER_920FWSM="$BASE_VER$DEVICE_VER_G920F$VERWSM"
HACKER_VER_925F="$BASE_VER$DEVICE_VER_G925F$VER"
HACKER_VER_925FWSM="$BASE_VER$DEVICE_VER_G925F$VERWSM"
KERNEL_NAME_G920F="$ZIP_VER$DEVICE_VER_G920F$VER"
KERNEL_NAME_WSM_G920F="$ZIP_VER$DEVICE_VER_G920F$VERWSM"
KERNEL_NAME_G925F="$ZIP_VER$DEVICE_VER_G925F$VER"
KERNEL_NAME_WSM_G925F="$ZIP_VER$DEVICE_VER_G925F$VERWSM"
RAMDISK=$BI_DIR/boot/ramdisk
PATCH=$KERNEL_DIR/build/patch;

backup_file() { cp $1 $1~; }

replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

replace_section() {
  line=`grep -n "$2" $1 | cut -d: -f1`;
  sed -i "/${2}/,/${3}/d" $1;
  sed -i "${line}s;^;${4}\n;" $1;
}

remove_section() {
  sed -i "/${2}/,/${3}/d" $1;
}

insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;${5}\n;" $1;
  fi;
}

replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

remove_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}d" $1;
  fi;
}

prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

insert_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;\n;" $1;
    sed -i "$((line - 1))r $patch/$5" $1;
  fi;
}

append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\n" >> $1;
  fi;
}

replace_file() {
  cp -pf $patch/$3 $1;
  chmod $2 $1;
}

CLEAN()
{
	echo ""
	echo "=============================================="
	echo "START: MAKE CLEAN"
	echo "=============================================="
	echo ""
	make clean
	make distclean
	make mrproper
	find . -name "*.dtb" -exec rm {} \;
	find . -type f -name "*~" -exec rm -f {} \;
	find . -type f -name "*orig" -exec rm -f {} \;
	find . -type f -name "*rej" -exec rm -f {} \;
	find . -name "*.ko" -exec rm {} \;
	ccache -C	
	echo ""
	echo "=============================================="
	echo "END: MAKE CLEAN"
	echo "=============================================="
	echo ""
}

CLEANCONFIG()
{	
	echo ""
	echo "=============================================="
	echo "START: CLEAN CONFIG"
	echo "=============================================="
	echo ""	
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_ZONE_DMA is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_WITH_CCACHE is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_WITH_GRAPHITE is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_CPU_FREQ_GOV_ONDEMAND is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_CPU_FREQ_GOV_CONSERVATIVE is not set";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_TCP_CONG_WESTWOOD=m";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_TCP_CONG_HTCP=m";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_SEC_RESTRICT_ROOTING=y";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_SEC_RESTRICT_SETUID=y";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_SEC_RESTRICT_FORK=y";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_SEC_RESTRICT_ROOTING_LOG=y";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_KSM is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_CLEANCACHE is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_INPUT_JOYSTICK is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_USB_OTG is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_ISO9660_FS is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_UDF_FS is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_NTFS_FS is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_CIFS is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_RD_LZMA is not set";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_WQ_POWER_EFFICIENT_DEFAULT is not set";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_PM_DEBUG=y";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_PM_ADVANCED_DEBUG=y";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_PM_TEST_SUSPEND is not set";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_PM_SLEEP_DEBUG=y";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_PM_DEBUG is not set";
	remove_line $CONFIG_DIR/$CONFIG "CONFIG_HAVE_64BIT_ALIGNED_ACCESS=y";
	remove_line $CONFIG_DIR/$CONFIG "# CONFIG_SCHED_HMP_LITTLE_PACKING is not set";
	echo ""
	echo "=============================================="
	echo "END: CLEAN CONFIG"
	echo "=============================================="
	echo ""
}

CHANGELOG()
{
	echo "Make Changelog from Github Repo"
	github_changelog_generator HRTKernel/Hacker_Kernel_SM-G92X_MM
	echo "Done!"
}

BUILD_BASE()
{
	export ARCH=arm64
        export SUBARCH=arm64
	export KBUILD_BUILD_USER=thehacker911
	export KBUILD_BUILD_HOST=smartlounge.eu
        export USE_CCACHE=1
        export USE_SEC_FIPS_MODE=true
        export ENABLE_GRAPHITE=true
	export CROSS_COMPILE=$BUILD_CROSS_COMPILE
}

START_BUILD()
{
	make ARCH=arm64 $KERNEL_DEFCONFIG
	make ARCH=arm64 -j$BUILD_JOB_NUMBER
}

SOUND_BASE_CLEAN()
{
        rm -rf $BI_DIR/boot
        rm -rf $KERNEL_DIR/$CONFIG_DIR/$CONFIG
        rm -rf $KERNEL_DIR/sound_mod/sound/soc/codecs/arizona-control.c;
        rm -rf $KERNEL_DIR/sound_mod/sound/soc/codecs/clearwater.c;
        rm -rf $KERNEL_DIR/sound_mod/include/linux/mfd/arizona/control.h;
        rm -rf $KERNEL_DIR/sound_mod/sound/soc/codecs/Makefile;
        rm -rf $KERNEL_DIR/sound_mod/drivers/base/regmap/regmap.c;
        sleep 2
}

PATCH_RAMDISK()
{
	echo ""
	echo "=============================================="
	echo "START: PATCH RAMDISK"
	echo "=============================================="
	echo ""
	sleep 1
	CLEANCONFIG
	sleep 1
	echo "$KERNEL_CONFIG" >> $KERNEL_DIR/$CONFIG_DIR/$CONFIG
	sleep 1

	# backup
	backup_file $RAMDISK/default.prop;
	backup_file $RAMDISK/init.rc;
	backup_file $RAMDISK/fstab.samsungexynos7420.fwup;
	backup_file $RAMDISK/fstab.samsungexynos7420;
	backup_file $RAMDISK/init.environ.rc;
	
	# hacker init
	HACKERINIT=`cat $PATCH/init.hacker.rc`
	echo "$HACKERINIT" > $RAMDISK/init.hacker.rc
	
	# default.prop
	replace_string $RAMDISK/default.prop "persist.security.ams.enforcing=0" "persist.security.ams.enforcing=1" "persist.security.ams.enforcing=0";
	replace_string $RAMDISK/default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";
	replace_string $RAMDISK/default.prop "ro.debuggable=1" "ro.debuggable=0" "ro.debuggable=1";
	replace_string $RAMDISK/default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
	replace_string $RAMDISK/default.prop "persist.sys.usb.config=mtp,adb" "persist.sys.usb.config=mtp" "persist.sys.usb.config=mtp,adb";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "debug.atrace.tags.enableflags=0" "persist.cne.feature=0\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "persist.cne.feature=0" "ro.config.tima=0\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.config.tima=0" "ro.config.knox=0\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.config.knox=0" "androidboot.selinux=0\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "androidboot.selinux=0" "ro.securestorage.knox=false\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.securestorage.knox=false" "ro.securestorage.support=false\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.securestorage.support=false" "ro.security.mdpp.ux=Disabled\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.security.mdpp.ux=Disabled" "wlan.wfd.hdcp=disable\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "wlan.wfd.hdcp=disable" "ro.config.dha_cached_min=12\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.config.dha_cached_min=12" "ro.config.dha_cached_max=24\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.config.dha_cached_max=24" "ro.config.dha_empty_min=8\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.config.dha_empty_min=8" "ro.config.dha_lmk_scale=1\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "ro.config.dha_lmk_scale=1" "sys.config.samp_spcm_enable=false\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "sys.config.samp_spcm_enable=false" "sys.config.spcm_db_enable=false\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "sys.config.spcm_db_enable=false" "sys.config.spcm_db_launcher=false\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "sys.config.spcm_db_launcher=false" "sys.config.spcm_preload_enable=false\n";
	insert_line $RAMDISK/default.prop "# HRT KERNEL" after "debug.atrace.tags.enableflags=0" "# HRT KERNEL\n";

	# su
	if [ "`grep "    # HRT-KERNEL-SU" $RAMDISK/init.rc`" != "" ]; then
		echo ""
	else
		SUPATCH=`cat $PATCH/su_patch`
		SUSCRIPT=`cat $PATCH/launch_daemonsu.sh`
		echo "$SUPATCH" >> $RAMDISK/init.rc
		echo "$SUSCRIPT" > $RAMDISK/sbin/launch_daemonsu.sh
	fi
	if [ "`grep "# HRT-KERNEL-SU" $RAMDISK/fstab.samsungexynos7420.fwup`" != "" ]; then
		echo ""
	else
		fstabsamsungexynos7420fwuppatch=`cat $PATCH/fstab.samsungexynos7420.fwup_patch`
		echo "$fstabsamsungexynos7420fwuppatch" > $RAMDISK/fstab.samsungexynos7420.fwup
	fi
	if [ "`grep "# HRT-KERNEL-SU" $RAMDISK/fstab.samsungexynos7420`" != "" ]; then
		echo ""
	else
		fstabsamsungexynos7420patch=`cat $PATCH/fstab.samsungexynos7420_patch`
		echo "$fstabsamsungexynos7420patch" > $RAMDISK/fstab.samsungexynos7420
	fi
	insert_line $RAMDISK/init.environ.rc "    # HRT-KERNEL-SU" before "export ANDROID_BOOTLOGO 1" "    export PATH /su/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin\n";
	insert_line $RAMDISK/init.environ.rc "    # HRT-KERNEL-SU" before "export ANDROID_BOOTLOGO 1" "    # HRT-KERNEL-SU\n";
	insert_line $RAMDISK/init.rc "    # HRT-KERNEL-SU" before "mkdir /data 0771 system system" "    mkdir /su 0755 root root # create mount point for SuperSU\n";
	insert_line $RAMDISK/init.rc "    # HRT-KERNEL-SU" before "mkdir /data 0771 system system" "    # HRT-KERNEL-SU\n";

	# init.rc
	if [ "`grep "# Include hacker extra init file" $RAMDISK/init.rc`" != "" ]; then
		echo ""
	else
		INITPATCH=`cat $PATCH/init_patch`
		HACKERSCRIPT=`cat $PATCH/hacker.sh`
		HACKERFILE=`cat $PATCH/hrt`
		echo "$INITPATCH" >> $RAMDISK/init.rc
		echo "$HACKERSCRIPT" > $RAMDISK/sbin/hacker.sh
		echo "$HACKERFILE" > $RAMDISK/sbin/hrt
	fi
	insert_line $RAMDISK/init.rc "# Include hacker extra init file" after "import /init.rilcommon.rc" "import /init.hacker.rc\n";
	insert_line $RAMDISK/init.rc "# Include hacker extra init file" after "import /init.rilcommon.rc" "# Include hacker extra init file\n";

	# synapse
	rm -rf $RAMDISK/res 
	cp -r $KERNEL_DIR/build/res $RAMDISK/res
	
	# fix permissions
	cd $RAMDISK
	chmod 644 file_contexts
	chmod 644 se*
	chmod 644 *.rc
	chmod 750 init*
	chmod 640 fstab*
	chmod 644 default.prop
	chmod 771 data
	chmod 755 dev
	#chmod 755 lib/modules/*
	chmod 755 proc
	chmod 755 res
	chmod 755 res/*
	chmod 755 sbin
	chmod 755 sbin/*
	cd sbin
	#chmod 755 su
	#chmod 664 su/*
	chmod 644 *.sh
	#chmod 644 uci
	cd ../
	chmod 755 init
	chmod 755 sys
	chmod 755 system
	cd $KERNEL_DIR
	echo ""
	echo "=============================================="
	echo "END: PATCH RAMDISK"
	echo "=============================================="
	echo ""
}

WITHSOUNDMOD()
{
        cp $KERNEL_DIR/sound_mod/build_with_sound_mod/arizona-control.c $KERNEL_DIR/sound/soc/codecs/arizona-control.c;
        cp $KERNEL_DIR/sound_mod/build_with_sound_mod/clearwater.c $KERNEL_DIR/sound/soc/codecs/clearwater.c;
        cp $KERNEL_DIR/sound_mod/build_with_sound_mod/control.h $KERNEL_DIR/include/linux/mfd/arizona/control.h;
        cp $KERNEL_DIR/sound_mod/build_with_sound_mod/Makefile $KERNEL_DIR/sound/soc/codecs/Makefile;
        cp $KERNEL_DIR/sound_mod/build_with_sound_mod/regmap.c $KERNEL_DIR/drivers/base/regmap/regmap.c;
}

WITHOUTSOUNDMOD()
{
        cp $KERNEL_DIR/sound_mod/build_without_sound_mod/clearwater.c $KERNEL_DIR/sound/soc/codecs/clearwater.c;
        cp $KERNEL_DIR/sound_mod/build_without_sound_mod/Makefile $KERNEL_DIR/sound/soc/codecs/Makefile;
        cp $KERNEL_DIR/sound_mod/build_without_sound_mod/regmap.c $KERNEL_DIR/drivers/base/regmap/regmap.c;
}

SEANDROIDENFORCE()
{
	echo -n "SEANDROIDENFORCE" >> boot.img
}

BUILD_KERNEL_G920F()
{	
	CLEAN
	echo ""
	echo "=============================================="
	echo "START: BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "$HACKER_VER_920F"
	export LOCALVERSION=-`echo $HACKER_VER_920F`
	BUILD_BASE
	START_BUILD
	echo ""
	echo "================================="
	echo "END: BUILD_KERNEL"
	echo "================================="
	echo ""
}

BUILD_KERNEL_G925F()
{	
	CLEAN
	echo ""
	echo "=============================================="
	echo "START: BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "$HACKER_VER_925F"
	export LOCALVERSION=-`echo $HACKER_VER_925F`
	BUILD_BASE
	START_BUILD
	echo ""
	echo "================================="
	echo "END: BUILD_KERNEL"
	echo "================================="
	echo ""
}

BUILD_KERNEL_G920FWSM()
{	
	CLEAN
	echo ""
	echo "=============================================="
	echo "START: BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "$HACKER_VER_920FWSM"
	export LOCALVERSION=-`echo $HACKER_VER_920FWSM`
	BUILD_BASE
	START_BUILD
	echo ""
	echo "================================="
	echo "END: BUILD_KERNEL"
	echo "================================="
	echo ""
}

BUILD_KERNEL_G925FWSM()
{	
	CLEAN
	echo ""
	echo "=============================================="
	echo "START: BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "$HACKER_VER_925FWSM"
	export LOCALVERSION=-`echo $HACKER_VER_925FWSM`
	BUILD_BASE
	START_BUILD
	echo ""
	echo "================================="
	echo "END: BUILD_KERNEL"
	echo "================================="
	echo ""
}

REPACK_KERNEL_G920F()
{	
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_G920F" 
	if [ -e $BUILD_KERNEL_DIR/arch/arm64/boot/Image ]; then
	      cp -r $KERNEL_ZIMG $BOOTIMG_DIR_2/Image
	      cd build_image
	      mkdir backup_image
	      cp -r Image backup_image/g920fzImage
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G920F
	      cp dt/$DT_G920F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_G920F.zip META-INF system kernel data
	      mv $KERNEL_NAME_G920F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G920F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	
}

REPACK_KERNEL_G920FWSM()
{	
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_WSM_G920F" 
	if [ -e $BUILD_KERNEL_DIR/arch/arm64/boot/Image ]; then
	      cp -r $KERNEL_ZIMG $BOOTIMG_DIR_2/Image
	      cd build_image
	      mkdir backup_image
	      cp -r Image backup_image/g920fwsmzImage
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      SEANDROIDENFORCE
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G920F
	      cp dt/$DT_G920F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_WSM_G920F.zip META-INF system kernel data
	      mv $KERNEL_NAME_WSM_G920F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G920F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	
}

REPACK_KERNEL_G925F()
{	
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_G925F" 
	if [ -e $BUILD_KERNEL_DIR/arch/arm64/boot/Image ]; then
	      cp -r $KERNEL_ZIMG $BOOTIMG_DIR_2/Image
	      cd build_image
	      mkdir backup_image
	      cp -r Image backup_image/g925fzImage
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G925F
	      cp dt/$DT_G925F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_G925F.zip META-INF system kernel data
	      mv $KERNEL_NAME_G925F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G925F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	
}

REPACK_KERNEL_G925FWSM()
{	
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_WSM_G925F" 
	if [ -e $BUILD_KERNEL_DIR/arch/arm64/boot/Image ]; then
	      cp -r $KERNEL_ZIMG $BOOTIMG_DIR_2/Image
	      cd build_image
	      mkdir backup_image
	      cp -r Image backup_image/g925fwsmzImage
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G925F
	      cp dt/$DT_G925F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_WSM_G925F.zip META-INF system kernel data
	      mv $KERNEL_NAME_WSM_G925F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G925F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	
}

REPACK_ONLY_G920F()
{
rm -rf ./repackg920f.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_G920F" 
	if [ -e $BOOTIMG_DIR_2/backup_image/g920fzImage ]; then
	      cp -r $BOOTIMG_DIR_2/backup_image/g920fzImage $BOOTIMG_DIR_2/Image
	      cp $KERNEL_DIR/build/dt/$DT_G920F $BI_DIR/dt/$DT_G920F
	      cd build_image
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G920F
	      cp dt/$DT_G920F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_G920F.zip META-INF system kernel data
	      mv $KERNEL_NAME_G920F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G920F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./repackg920f.log	
}

REPACK_ONLY_G925F()
{
rm -rf ./repackg920f.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_G925F" 
	if [ -e $BUILD_KERNEL_DIR/backup_image/g925fzImage ]; then
	      cp -r $BUILD_KERNEL_DIR/backup_image/g925fzImage $BOOTIMG_DIR_2/Image
	      cp $KERNEL_DIR/build/dt/$DT_G925F $BI_DIR/dt/$DT_G925F
	      cd build_image
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G925F
	      cp dt/$DT_G925F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_G925F.zip META-INF system kernel data
	      mv $KERNEL_NAME_G925F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G925F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./repackg925f.log	
}

REPACK_ONLY_G920FWSM()
{
rm -rf ./repackg920fwsm.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_WSM_G920F" 
	if [ -e $BUILD_KERNEL_DIR/backup_image/g920fwsmzImage ]; then
	      cp -r $BUILD_KERNEL_DIR/backup_image/g920fwsmzImage $BOOTIMG_DIR_2/Image
	      cp $KERNEL_DIR/build/dt/$DT_G920F $BI_DIR/dt/$DT_G920F
	      cd build_image
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G920F
	      cp dt/$DT_G920F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_WSM_G920F.zip META-INF system kernel data
	      mv $KERNEL_NAME_WSM_G920F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G920F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./repackg920fwsm.log	
}

REPACK_ONLY_G925FWSM()
{
rm -rf ./repackg925fwsm.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
	echo ""
	echo "=============================================="
	echo "START: REPACK_KERNEL"
	echo "=============================================="
	echo ""
	      echo "$KERNEL_NAME_WSM_G925F" 
	if [ -e $BUILD_KERNEL_DIR/backup_image/g925fwsmzImage ]; then
	      cp -r $BUILD_KERNEL_DIR/backup_image/g925fwsmzImage $BOOTIMG_DIR_2/Image
	      cp $KERNEL_DIR/build/dt/$DT_G925F $BI_DIR/dt/$DT_G925F
	      cd build_image
	      cp -r Image boot/zImage
	      rm output_kernel/*.zip
	      echo "Making boot.img ..."
	      #$DTBTOOL -o dt.img -s $BOARD_KERNEL_PAGESIZE -p ../scripts/dtc/ ../arch/arm64/boot/dts/ | sleep 1	      
	      chmod a+r dt/$DT_G925F
	      cp dt/$DT_G925F boot/dt.img
	      ./mkboot boot boot.img	      
	      echo "Making zip ..."
	      SEANDROIDENFORCE
	      cp $BOOTIMG $FLASH_ZIP_FILES/kernel/boot.img
	      cd $FLASH_ZIP_FILES
	      zip -r $KERNEL_NAME_WSM_G925F.zip META-INF system kernel data
	      mv $KERNEL_NAME_WSM_G925F.zip $OUTPUT_DIR
	      echo "Making cleaning ..."
	      cd ..
	      rm dt/$DT_G925F
	      rm boot.img
	      rm Image
	      rm zip_files/kernel/boot.img
	      rm boot/zImage
	      rm boot/dt.img
	      cd $KERNEL_DIR
	      CHANGELOG
	      echo "All Done!"
	
	      echo ""
	      echo "================================="
	      echo "END: REPACK_KERNEL"
	      echo "================================="
	      echo ""
	      
	else
	
	      echo ""
	      echo "================================="
	      echo "END: FAIL KERNEL BUILD!"
	      echo "================================="
	      echo ""
	      exit 0;
	fi;
	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./repackg925fwsm.log	
}

# MAIN FUNCTION
G920F()
{
rm -rf ./buildg920f.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
        echo ""
        echo "Build G920F with sound mod"
        sleep 2
        rm -rf $BI_DIR/dt/$DT_G920F
        rm -rf $BI_DIR/boot
	SOUND_BASE_CLEAN
        cp $KERNEL_DIR/build/dt/$DT_G920F $BI_DIR/dt/$DT_G920F
        cp $KERNEL_DIR/build/boot/boot-g920f.img $BI_DIR/boot.img
        cd $BI_DIR
        ./mkboot boot.img boot
	rm boot.img
	rm Image
	rm zip_files/kernel/boot.img
	rm boot/zImage
	rm boot/dt.img	
        cd $KERNEL_DIR
        cp $KERNEL_DIR/$CONFIG_DIR/$CONFIG_G920F $KERNEL_DIR/$CONFIG_DIR/$CONFIG
	WITHSOUNDMOD
	PATCH_RAMDISK
        sleep 1
	BUILD_KERNEL_G920F
	REPACK_KERNEL_G920F

	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./buildg920f.log
}

G920FWSM()
{
rm -rf ./buildg920fwsm.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
        echo ""
        echo "Build G920F without sound mod"
        sleep 2
        rm -rf $BI_DIR/dt/$DT_G920F
        rm -rf $BI_DIR/boot
	SOUND_BASE_CLEAN
        cp $KERNEL_DIR/build/dt/$DT_G920F $BI_DIR/dt/$DT_G920F
        cp $KERNEL_DIR/build/boot/boot-g920f.img $BI_DIR/boot.img
        cd $BI_DIR
        ./mkboot boot.img boot
	rm boot.img
	rm Image
	rm zip_files/kernel/boot.img
	rm boot/zImage
	rm boot/dt.img	
        cd $KERNEL_DIR
        cp $KERNEL_DIR/$CONFIG_DIR/$CONFIG_G920F $KERNEL_DIR/$CONFIG_DIR/$CONFIG
	WITHOUTSOUNDMOD
	PATCH_RAMDISK
        sleep 1
	BUILD_KERNEL_G920FWSM
	REPACK_KERNEL_G920FWSM

	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./buildg920fwsm.log
}

G925F()
{
rm -rf ./buildg925f.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
        echo ""
        echo "Build G925F with sound mod"
        sleep 2
        rm -rf $BI_DIR/dt/$DT_G925F
        rm -rf $BI_DIR/boot
	SOUND_BASE_CLEAN
        cp $KERNEL_DIR/build/dt/$DT_G925F $BI_DIR/dt/$DT_G925F
        cp $KERNEL_DIR/build/boot/boot-g925f.img $BI_DIR/boot.img
        cd $BI_DIR
        ./mkboot boot.img boot
	rm boot.img
	rm Image
	rm zip_files/kernel/boot.img
	rm boot/zImage
	rm boot/dt.img	
        cd $KERNEL_DIR
        cp $KERNEL_DIR/$CONFIG_DIR/$CONFIG_G925F $KERNEL_DIR/$CONFIG_DIR/$CONFIG
        WITHSOUNDMOD
	PATCH_RAMDISK
        sleep 1
	BUILD_KERNEL_G925F
	REPACK_KERNEL_G925F

	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./buildg925f.log
}

G925FWSM()
{
rm -rf ./buildg925fwsm.log
(
	START_TIME=`date +%s`
	BUILD_DATE=`date +%m-%d-%Y`
	echo ""
        echo "Build G925F without sound mod"
        sleep 2
        rm -rf $BI_DIR/dt/$DT_G925F
        rm -rf $BI_DIR/boot
	SOUND_BASE_CLEAN
        cp $KERNEL_DIR/build/dt/$DT_G925F $BI_DIR/dt/$DT_G925F
        cp $KERNEL_DIR/build/boot/boot-g925f.img $BI_DIR/boot.img
        cd $BI_DIR
        ./mkboot boot.img boot
	rm boot.img
	rm Image
	rm zip_files/kernel/boot.img
	rm boot/zImage
	rm boot/dt.img	
        cd $KERNEL_DIR
        cp $KERNEL_DIR/$CONFIG_DIR/$CONFIG_G925F $KERNEL_DIR/$CONFIG_DIR/$CONFIG
        WITHOUTSOUNDMOD
	PATCH_RAMDISK
        sleep 1
	BUILD_KERNEL_G925FWSM
	REPACK_KERNEL_G925FWSM

	END_TIME=`date +%s`
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./buildg920fwsm.log
}

BUILD_KERNEL_MENU()
{
while true; do
    clear
    echo ""
    echo "a = Build G920F with sound mod"
    echo "b = Build G920F without sound mod"
    echo "c = Build G925F with sound mod"
    echo "d = Build G925F without sound mod"
    echo ""
    echo "q = Back to Main Menu"
    echo ""
    read -p "Do you wish to build? = " abcdq
    case $abcdq in
        [Aa]* )
        G920F;;
        
        [Bb]* )
        G920FWSM;;
        
        [Cc]* )
        G925F;;
        
        [Dd]* )
        G925FWSM;;
            
        [Qq]* )
        MAIN_MENU;;
        
        * ) echo "Please answer.";;

    esac
done
}

REPACK_KERNEL_MENU()
{
while true; do
    clear
    echo ""
    echo "a = Repack G920F with sound mod"
    echo "b = Repack G920F without sound mod"
    echo "c = Repack G925F with sound mod"
    echo "d = Repack G925F without sound mod"
    echo ""
    echo "q = Back to Main Menu"
    echo ""
    read -p "Do you wish to build? = " abcdq
    case $abcdq in
        [Aa]* )
        REPACK_ONLY_G920F;;
        
        [Bb]* )
        REPACK_ONLY_G920FWSM;;
        
        [Cc]* )
        REPACK_ONLY_G925F;;
        
        [Dd]* )
        REPACK_ONLY_G925FWSM;;
                    
        [Qq]* )
        MAIN_MENU;;
        
        * ) echo "Please answer.";;

    esac
done
}

MAIN_MENU()
{
while true; do
    clear
    echo ""
    echo "a = Build Kernel"
    echo "b = Repack Kernel"
    echo ""
    echo "q = Exit"
    echo ""
    read -p "Do you wish to build? = " abq
    case $abq in
        [Aa]* )
        BUILD_KERNEL_MENU;;
        
        [Bb]* )
        REPACK_KERNEL_MENU;;
     
        [Qq]* )
        exit 0;;
        
        * ) echo "Please answer.";;

    esac
done
}

MAIN_MENU

# Credits:
# Samsung
# google
# osm0sis
# cyanogenmod
# kylon 
