#!/usr/bin/env bash
# Copyright (C) 2019-2020 Jago Gardiner (nysascape)
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# CI build script

# Needed exports
export TELEGRAM_TOKEN=1176154929:AAEwBruEeSm92J2VgHGrLuJroL4oKkd0j-k
export ANYKERNEL=$(pwd)/anykernel3

# Avoid hardcoding things
KERNEL=Zhard
DEFCONFIG=whyred_defconfig
DEVICE=Whyred
CIPROVIDER=CircleCI
KERNELFW=Global
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"

# Kernel groups
CI_CHANNEL=-1001174078190
TG_GROUP=-1001347410949

# Clang is annoying
PATH="${KERNELDIR}/clang/bin:${PATH}"

# Kernel revision
KERNELRELEASE=HMP

# Function to replace defconfig versioning
setversioning() {
    if [[ "${PARSE_BRANCH}" =~ "reina-newcam"* ]]; then
    	# For staging branch
	    KERNELTYPE=Gabut
	    KERNELNAME="${KERNEL}-${KERNELRELEASE}-NewCam-$(date +%y%m%d-%H%M)"
	    sed -i "50s/.*/CONFIG_LOCALVERSION=\"-${KERNELNAME}\"/g" arch/arm64/configs/${DEFCONFIG}
    else
	    # Dunno when this will happen but we will cover, just in case
	    KERNELTYPE=${PARSE_BRANCH}
	    KERNELNAME="${KERNEL}-${KERNELRELEASE}-OldCam-$(date +%y%m%d-%H%M)"
        sed -i "50s/.*/CONFIG_LOCALVERSION=\"-${KERNELNAME}\"/g" arch/arm64/configs/${DEFCONFIG}
    fi

    # Export our new localversion and zipnames
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

# Send to main group
tg_groupcast() {
    "${TELEGRAM}" -c "${TG_GROUP}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# Send to channel
tg_channelcast() {
    "${TELEGRAM}" -c "${CI_CHANNEL}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# Fix long kernel strings
kernelstringfix() {
    git config --global user.name "Reinazhard"
    git config --global user.email "muh.alfarozy@gmail.com"
    git add .
    git commit -m "stop adding dirty"
}

# Make the kernel
makekernel() {
    # Clean any old AnyKernel
    rm -rf ${ANYKERNEL}
    git clone https://github.com/Reinazhard/AnyKernel3 -b master anykernel3
    kernelstringfix
    export CROSS_COMPILE="${KERNELDIR}/gcc/bin/aarch64-maestro-linux-gnu-"
    export CROSS_COMPILE_ARM32="${KERNELDIR}/gcc32/bin/arm-maestro-linux-gnueabi-"
    export ARCH=arm64
    export SUBARCH=arm64
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${COMPILER_TYPE}" =~ "clang"* ]]; then
        make -j$(nproc --all) CC=clang O=out ARCH=arm64 CLANG_TRIPLE=aarch64-maestro-linux-gnu-
    else
	    make -j$(nproc --all) O=out ARCH=arm64 CROSS_COMPILE="${KERNELDIR}/gcc/bin/aarch64-maestro-linux-gnu-" CROSS_COMPILE_ARM32="${KERNELDIR}/gcc32/bin/arm-maestro-linux-gnueabi-"
    fi

    # Check if compilation is done successfully.
    if ! [ -f "${OUTDIR}"/arch/arm64/boot/Image.gz-dtb ]; then
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "Build Failed LMAO !!, See buildlog to fix errors"
	    tg_channelcast "Build for ${DEVICE} (${KERNELFW}) <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check ${CIPROVIDER} for errors!"
	    tg_groupcast "Build for ${DEVICE} (${KERNELFW}) <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check ${CIPROVIDER} for errors @eve_enryu @reinazhardci"
	    exit 1
    fi
}

# Ship the compiled kernel
shipkernel() {
    # Copy compiled kernel
    cp "${OUTDIR}"/arch/arm64/boot/Image.gz-dtb "${ANYKERNEL}"/

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" *

    # Sign the zip before sending it to Telegram
    curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/AnyKernel2/master/zipsigner-3.0.jar
    java -jar zipsigner-3.0.jar ${TEMPZIPNAME} ${ZIPNAME}

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -c "${CI_CHANNEL}"

    # Go back for any extra builds
    cd ..
}



# Fix for CI builds running out of memory
fixcilto() {
    sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/g' arch/arm64/configs/${DEFCONFIG}
    sed -i 's/CONFIG_LD_DEAD_CODE_DATA_ELIMINATION=y/# CONFIG_LD_DEAD_CODE_DATA_ELIMINATION is not set/g' arch/arm64/configs/${DEFCONFIG}
}

## Start the kernel buildflow ##
setversioning
fixcilto
tg_groupcast "${KERNEL} compilation clocked at $(date +%Y%m%d-%H%M)!"
tg_channelcast "Compiler: <code>${COMPILER_STRING}</code>" \
	"Device: <b>${DEVICE}</b>" \
	"Kernel: <code>${KERNEL}, release ${KERNELRELEASE}</code>" \
	"Branch: <code>${PARSE_BRANCH}</code>" \
	"Commit point: <code>${COMMIT_POINT}</code>" \
	"Clocked at: <code>$(date +%Y%m%d-%H%M)</code>"
START=$(date +"%s")
makekernel || exit 1
shipkernel
setversioning
makekernel || exit 1
shipkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_channelcast "Build for ${DEVICE} with ${COMPILER_STRING} took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
tg_groupcast "Build for ${DEVICE} with ${COMPILER_STRING} took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! @reinazhardci"
