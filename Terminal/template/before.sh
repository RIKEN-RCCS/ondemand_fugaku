#!/usr/bin/env bash

# Export the module function if it exists
[[ $(type -t module) == "function" ]] && export -f module

# Export compute node the script is running on
#host="$(hostname -s).cloud.r-ccs.riken.jp"
host=$(hostname)
HOST="$host"
export host HOST

# Find available port to run server on
port=$(find_port)
PORT="$port"
export port PORT

# Generate SHA1 encrypted password (requires OpenSSL installed)
password="$(create_passwd 24)"
PASSWORD="$password"
export password PASSWORD

# Setup TMP Dir
export TMPDIR=/worktmp
TMPDIR="$(mktemp -d -p "/tmp" -t "$USER-tmpdir-XXXXXX")"
TMP_DIR="$TMPDIR"
chmod 700 "$TMPDIR"
export TMPDIR TMP_DIR

# Setup XDG_RUNTIME_DIR
XDG_RUNTIME_DIR="$(mktemp -d -p "/tmp" -t "$USER-xdgrun-XXXXXX")"
chmod 700 "$XDG_RUNTIME_DIR"
export XDG_RUNTIME_DIR

# Load Form Information
OOD_SR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
if [ -f "${OOD_SR}/form.sh" ]; then
  # shellcheck disable=SC1090,SC1091
  source "${OOD_SR}/form.sh"
fi
unset OOD_SR

# Create Function for Slurm Cleanup
#function slurm_env_clean {
#  eval "$(printenv | grep -i ^slurm | sed 's/^SLURM/export OOD_SLURM/')"
#  # shellcheck disable=SC2046
#  unset $(compgen -v 'SLURM')
#  echo "All environment variables starting with 'SLURM' have been renamed to be prefixed with 'OOD_'."
#  printenv | grep -i '^OOD_SLURM'
#}
#export -f slurm_env_clean
