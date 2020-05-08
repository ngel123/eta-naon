#!/usr/bin/env bash
#
# Copyright (C) 2019 nysascape
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# Probably the 3rd bad apple coming
# Enviroment variables

# Export KERNELDIR as en environment-wide thingy
# We start in scripts, so like, don't clone things there
KERNELDIR="$(pwd)"
SCRIPTS=$HOMEscripts
OUTDIR=${KERNELDIR}/out

# Pick your poison
        COMPILER_STRING='Avalon Clang (latest)'
	COMPILER_TYPE='clang'
else
        # Default to GCC from Arter
        COMPILER_STRING='MAESTRO-GCC 9.x'
	COMPILER_TYPE='MAESTRO-GCC9.x'
fi

export COMPILER_STRING COMPILER_TYPE KERNELDIR SCRIPTS OUTDIR

git clone https://github.com/fabianonline/telegram.sh/ telegram

# Export Telegram.sh
TELEGRAM=${KERNELDIR}/telegram/telegram

export TELEGRAM JOBS
