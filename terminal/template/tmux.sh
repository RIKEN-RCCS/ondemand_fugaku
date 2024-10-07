#!/usr/bin/env bash

# load the required modules
#module -q load spack/2022a  gcc/12.1.0-2022a-gcc_8.5.0-ivitefn
#module -q load tmux/3.2a-2022a-gcc_12.1.0-jwjkrr7

# set environment variables
TMUX_PATH="/opt/tmux/bin/tmux"
TMUX_SOCKET="J${SLURM_JOB_ID}.sock"
TMUX_SESSION="J${SLURM_JOB_ID}"
export TMUX_PATH TMUX_SOCKET TMUX_SESSION

# unload and cleanup modules
#module -q reset

# setup config file
if [ -f "${HOME}/.config/tmux/tmux.conf" ]; then
	TMUX_CONFIG_PATH="${HOME}/.config/tmux/tmux.conf"
elif [ -f "${HOME}/.tmux.conf" ]; then
	TMUX_CONFIG_PATH="${HOME}/.tmux.conf"
else
	mkdir -p "${HOME}/.config/tmux"
	cp -f "$OOD_STAGED_ROOT/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
	TMUX_CONFIG_PATH="${HOME}/.config/tmux/tmux.conf"
	ln -sf "${HOME}/.config/tmux/tmux.conf" "${HOME}/.tmux.conf"
fi
export TMUX_CONFIG_PATH

# setup function to use discovered path
function tmux {
	"$TMUX_PATH" "$@"
}
export -f tmux

# run app
/opt/tmux/bin/tmux -f "$TMUX_CONFIG_PATH" -L "$TMUX_SOCKET" new -A -s "$TMUX_SESSION"
