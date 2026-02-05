#!/usr/bin/env bash

# set environment variables
TMUX_PATH="/home/apps/oss/tmux/`arch`/tmux-3.6a/bin/tmux"
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
$TMUX_PATH -f "$TMUX_CONFIG_PATH" -L "$TMUX_SOCKET" new -A -s "$TMUX_SESSION"
