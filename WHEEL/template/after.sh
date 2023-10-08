echo "Waiting for WHEEL server to open port ${port}..."
echo "TIMING - Starting wait at: $(date)"
if wait_until_port_used "${host}:${port}" 600; then
  echo "Discovered WHEEL server listening on port ${port}!"
  echo "TIMING - Wait ended at: $(date)"
else
  echo "Timed out waiting for WHEEL server to open port ${port}!"
  echo "TIMING - Wait ended at: $(date)"
  pkill -P ${SCRIPT_PID}
  clean_up 1
fi
sleep 2
export BACKUP_EXT="wheel.bak"

if [ "x${WHEEL_GENERATE_KEYPAIR}" != "xYES" ];then
  echo 'key_mode is not "single-use key pair" so we dont touch authorized_keys and config file'
else

  PUBKEY=${HOME}/.wheel/wheel_tmp_pubkey

  #add pubkey to authorized_keys
  cp ${HOME}/.ssh/authorized_keys ${HOME}/.ssh/authorized_keys.${BACKUP_EXT}
  cat ${PUBKEY} >> ${HOME}/.ssh/authorized_keys


  #add ssh config to access fugaku
  cp ${HOME}/.ssh/config ${HOME}/.ssh/config.${BACKUP_EXT}
  {
  echo "HOST login.fugaku.r-ccs.riken.jp"
  echo "  IdentityFile /tmp_identify"
  } >> ${HOME}/.ssh/config

  #embed pubkey to restore.sh
  ESCAPED_PUBKEY_STRING=$(cat ${PUBKEY}|sed 's/[\/\.\*\^\$\[]/\\&/g' |sed 's/\]/\\]/g')
  echo original pubkey = $(cat ${PUBKEY})
  echo escaped  pubkey = ${ESCAPED_PUBKEY_STRING}

  sed -i -e "s/PUBKEY/${ESCAPED_PUBKEY_STRING}/" ./restore.sh


  #remove PUBKEY
  rm ${PUBKEY}

  sbatch -t 1 -p ondemand-reserved --dependency=afterany:${SLURM_JOBID} --open-mode=append -o output.log  restore.sh
fi
