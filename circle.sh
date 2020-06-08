#!/usr/bin/env bash
# Copyright (C) 2019-2020 Jago Gardiner (nysascape)
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# CI build script

# Needed exports
export TELEGRAM_TOKEN=1176154929:AAEwBruEeSm92J2VgHGrLuJroL4oKkd0j-k #Plox dont kang my bot, make ur own
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

#Kearipan Lokal
export KBUILD_BUILD_USER=reina
export KBUILD_BUILD_HOST=Laptop-Sangar

# Kernel groups
CI_CHANNEL=-1001174078190
TG_GROUP=-1001493260868

#Datetime
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
BUILD_DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")

# Clang is annoying
PATH="${KERNELDIR}/clang/bin:$PATH"

# Kernel revision
KERNELRELEASE=HMP

# Function to replace defconfig versioning
setversioning() {
    	# For staging branch
	    KERNELNAME="${KERNEL}-${KERNELRELEASE}-OldCam-${BUILD_DATE}"
	    sed -i "50s/.*/CONFIG_LOCALVERSION=\"-${KERNELNAME}\"/g" arch/arm64/configs/${DEFCONFIG}
    
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
    "${TELEGRAM}" -c "${CI_CHANNEL}" -H -D \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

paste() {
    curl -F document=build.log "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id="$CI_CHANNEL" \
			-F "disable_web_page_preview=true" \
			-F "parse_mode=html" 
}

stiker() {
	curl -s -F chat_id=$CI_CHANNEL -F sticker="CAACAgQAAx0CWQFaRAACFRle2yGs3_-88DGI9gQHrIc79PXHTQACegUAAqN9MRWn9pNmfKOxqRoE" https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
	}
# Stiker Error
stikerr() {
	curl -s -F chat_id=$CI_CHANNEL -F sticker="CAACAgUAAx0CWJTBcAABAVwjXttFXGel5rpdwQLKS1CVuuWAg5MAAkAAA_yDJT4AASnArwd-VosaBA" https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
	}
# Fin Error
finerr() {
        paste
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
			-d chat_id="$CI_CHANNEL" \
			-d "disable_web_page_preview=true" \
			-d "parse_mode=markdown" \
			-d text="Build throw an error(s)"
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
    export PATH="${KERNELDIR}/clang/bin:$PATH"
    #export CROSS_COMPILE=${KERNELDIR}/gcc/bin/aarch64-linux-gnu-
    #export CROSS_COMPILE_ARM32=${KERNELDIR}/gcc32/bin/arm-maestro-linux-gnueabi-
    make O=out ARCH=arm64 ${DEFCONFIG}
    make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    # Check if compilation is done successfully.
    if ! [ -f "${OUTDIR}"/arch/arm64/boot/Image.gz-dtb ]; then
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "build Failed LMAO !!, See buildlog to fix errors"
	    tg_channelcast "❌Build Failed in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
	    tg_groupcast "BUILD FAILED LMAO !! @eve_enryu @reinazhardci"
	    stikerr
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

# Ship China firmware builds
setnewcam() {
    export CAMLIBS=NewCam
    # Pick DSP change
    sed -i 's/CONFIG_XIAOMI_NEW_CAMERA_BLOBS=n/CONFIG_XIAOMI_NEW_CAMERA_BLOBS=y/g' arch/arm64/configs/${DEFCONFIG}
    echo -e "Newcam ready"
}

# Ship China firmware builds
clearout() {
    # Pick DSP change
    rm -rf out
    mkdir -p out
}

#Setver 2 for newcam
setver2() {
    KERNELNAME="${KERNEL}-${KERNELRELEASE}-NewCam-${BUILD_DATE}"
    sed -i "50s/.*/CONFIG_LOCALVERSION=\"-${KERNELNAME}\"/g" arch/arm64/configs/${DEFCONFIG}
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

# Fix for CI builds running out of memory
fixcilto() {
    sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/g' arch/arm64/configs/${DEFCONFIG}
    sed -i 's/CONFIG_LD_DEAD_CODE_DATA_ELIMINATION=y/# CONFIG_LD_DEAD_CODE_DATA_ELIMINATION is not set/g' arch/arm64/configs/${DEFCONFIG}
}

## Start the kernel buildflow ##
setversioning
fixcilto
tg_groupcast "🔨 Compilation started at $(date +%Y%m%d-%H%M)!"
tg_channelcast "🔨Kernel: <code>${KERNEL}, release ${KERNELRELEASE}</code>" \
	"Latest Commit: <code>${COMMIT_POINT}</code>" \
	"For moar cl, check my repo https://github.com/Reinazhard/kranul.git" 

START=$(date +"%s")
makekernel || exit 1
shipkernel
setver2
setnewcam
makekernel || exit 1
shipkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_channelcast "✅Build for ${DEVICE} with ${COMPILER_STRING} took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
tg_groupcast "Build for ${DEVICE} with ${COMPILER_STRING} took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! @reinazhardci"
stiker
