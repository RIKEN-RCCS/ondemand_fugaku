#!/bin/bash
#remove pubkey from authorized_keys
PUBLICKEY="PUBKEY"
ESCAPED_PUBLICKEY_STRING=$(echo "^${PUBLICKEY}"|sed 's/[\/\.\*\^\$\[]/\\&/g' |sed 's/\]/\\]/g' |sed 's/\\\^//')
echo ${ESCAPED_PUBLICKEY_STRING}

sed  -i -e "/${ESCAPED_PUBLICKEY_STRING}/d"  ${HOME}/.ssh/authorized_keys

diff ${HOME}/.ssh/authorized_keys.${BACKUP_EXT:=".wheel.bak"} ${HOME}/.ssh/authorized_keys
if [ $? == 0 ];then
 echo remove authorized_keys backup file
 rm ${HOME}/.ssh/authorized_keys.${BACKUP_EXT}
fi

#remove ssh config entry
sed -i -z -e 's/HOST login.fugaku.r-ccs.riken.jp\n *IdentityFile \/tmp_identify\n//g' ${HOME}/.ssh/config

diff  ${HOME}/.ssh/config.${BACKUP_EXT}  ${HOME}/.ssh/config
if [ $? == 0 ];then
  echo remove ssh config backup file
  rm ${HOME}/.ssh/config.${BACKUP_EXT}
fi
