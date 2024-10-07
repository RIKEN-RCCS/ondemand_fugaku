#!/usr/bin/env bash

# load the required modules
#module -q load spack/2022a gcc/12.1.0-2022a-gcc_8.5.0-ivitefn
#module -q load ttyd/1.7.0-2022a-gcc_12.1.0-3i53q3u

# set environment variables
TTYD_PATH="$(which --skip-alias --skip-functions ttyd)"
export TTYD_PATH

# unload and cleanup modules
#module -q reset

# setup function to use discovered path
function ttyd {
	"$TTYD_PATH" "$@"
}
export -f ttyd
