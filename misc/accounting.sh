#!/usr/bin/bash
#=============================================================================
OOD_BASE_DIR=/var/www/ood/apps/sys/ondemand_fugaku
ACCOUNTING_DIR=/system/ood/accounting
LOCKFILE=${ACCOUNTING_DIR}/lockfile
ELAPSED_TIME=${ACCOUNTING_DIR}/elapsed_time.txt
DATE_TXT=${ACCOUNTING_DIR}/date.txt
GROUP_DIR=${ACCOUNTING_DIR}/group
HOME_DIR=${ACCOUNTING_DIR}/home
GROUP_TMP=${GROUP_DIR}/group.tmp
DISK_TMP=${HOME_DIR}/disk.tmp
INODE_TMP=${HOME_DIR}/inode.tmp
#=============================================================================
ACCOUNTJ="/usr/local/bin/accountj"
ACCOUNTD="/usr/local/bin/accountd"
PJSTATA="/usr/local/bin/pjstata"
REMOTE_SSH=""
[ "$HOSTNAME" != "fn06sv04" ] && REMOTE_SSH="ssh login"
YEAR=$(date +%Y)
MONTH=$(date +%m)
YEAR=$(( $MONTH >= 1 && $MONTH <= 3 ? `expr ${YEAR} - 1` : ${YEAR} ))  # 年度なので、1月から3月の場合はYEARを1つ少なくする
FIRSTDAY=$(( $MONTH >= 4 && $MONTH <= 9 ? ${YEAR}0401 : ${YEAR}1001 )) # 前期の開始日は4/1、後期の開始日は10/1
#=============================================================================
# ディスク容量が95%以上の場合、スクリプトを停止
VAR=$(df / | tail -n 1 | awk '{print $5}' | sed -r 's/%//g')
[ ${VAR} -ge 95 ] && exit 1

# 前回作成されたロックファイルがある場合、スクリプトを停止
mkdir -p ${ACCOUNTING_DIR}
[ -e ${LOCKFILE} ] && exit 1
touch ${LOCKFILE}

# データ保存用ディレクトリの作成
mkdir -p ${GROUP_DIR} ${HOME_DIR}

#==============================================================================
# DATA領域
#==============================================================================
{
    # グループ名を抽出
    su - ktool -c "${REMOTE_SSH} ${ACCOUNTJ} -all-group -c" | tr -d '"' | tail -n +4 | awk -F, '{print $2}' > ${GROUP_TMP}

    # 上コマンドが失敗した時、ファイルがない時、中身が空の時にスクリプトを終了する
    if [ $? -ne 0 -o ! -e ${GROUP_TMP} -o ! -s ${GROUP_TMP} ]; then
	rm -f ${LOCKFILE} ${GROUP_TMP}
	exit 1
    fi

    # ファイルを一般ユーザが閲覧できないようにする
    chmod 600 ${GROUP_TMP}
    chown root:root ${GROUP_TMP}
    
    # グループ毎のバジェットを取得
    for II in `cat ${GROUP_TMP}`; do
	[ ${II} = "fujitsu" ] && continue

        # 各グループのディレクトリを作成
        DIR=${GROUP_DIR}/${II}
        mkdir -p ${DIR}
        chmod 750 ${DIR}
        chown root:${II} ${DIR}
	{
	    # グループ名1つ1つに対してaccountj -gを実行し、グループ毎のバジェットを取得
	    FILE=${DIR}/group_budget.csv
	    su - ktool -c "${REMOTE_SSH} ${ACCOUNTJ} -g ${II} -c -r 1 -e -E" | tr -d '"' | egrep '^SUBTHEME|^SUBTHEMEPERIOD|^EXCLUSIVEUSE|^RESOURCE_GROUP|^USER' | egrep -v '^USER_' > ${FILE}
	    
	    if [ $? -ne 0 ]; then
	      rm ${LOCKFILE} ${GROUP_TMP}
	      exit 1
	    fi
	    chmod 660 ${FILE}
	    chown root:${II} ${FILE}
	} &

	{
	    # グループ名1つ1つに対してaccountd -gを実行し、グループ毎のディスク使用量を取得
	    # -Eをつけると、/dataと/shareの情報も出力される
	    FILE=${DIR}/disk.csv
	    su - ktool -c "${REMOTE_SSH} ${ACCOUNTD} -g ${II} -c -E" | tr -d '"' | tail -n +5 > ${FILE}

	    if [ $? -ne 0 ]; then
	      rm ${LOCKFILE} ${GROUP_TMP}
              exit 1
	    fi

	    if [ -s ${FILE} ]; then
	      chmod 640 ${FILE}
	      chown root:${II} ${FILE}
	    else
	      rm -f ${FILE}
	    fi

	    # グループ名1つ1つに対してaccountd -g -iを実行し、グループ毎のi-node使用量を取得
	    # 時間削減のために、ディスクを使用しているグループだけ以降の処理を行う
	    if [ -s ${FILE} ]; then
	      FILE=${DIR}/inode.csv
	      su - ktool -c "${REMOTE_SSH} ${ACCOUNTD} -g ${II} -i -c" | tr -d '"' | tail -n +4 > ${FILE}
	      
	      if [ $? -ne 0 ]; then
	        rm ${LOCKFILE} ${GROUP_TMP}
	        exit 1
	      fi
	      
              if [ -s ${FILE} ]; then
                chmod 640 ${FILE}
                chown root:${II} ${FILE}
              else
                rm -f ${FILE}
              fi
	    fi

	    # ユーザ毎のバジェットを取得
	    # 上と同様にディスクを使用しているグループだけ以降の処理を行うが、
	    # rist-で始まるグループではディスクを利用していなくてもバジェットを利用しているので、それらは処理を行う
	    if [[ -s ${FILE} || ${II} == rist-* ]]; then
	      FILE_U=${DIR}/user_budget.csv
	      FILE_G=${DIR}/group_budget.csv

	      if [ `egrep '^SUBTHEMEPERIOD' ${FILE_G} | wc -l` -eq 0 ]; then
		# 随時課題の場合（前期・後期がない）、ACCOUNTJの情報を用いる
		egrep '^USER' ${FILE_G} | awk -F, '{print $2","$4}' > ${FILE_U}
	      else
		# 前期後期のある課題の場合、後期にACCOUNTJを用いると前期との合計値が出てしまうため、
		# PJSTATAを使って後期からの値を計算する（前期の場合も、上のif文内で処理しても良い）
	        # awkコマンドで下記のresource_info.rbを代替すると、CSVの要素の中にカンマがある場合に
	        # 対応できないため、rubyのCSVモジュールを使っている
	        su - ktool -c "${REMOTE_SSH} ${PJSTATA} -c -g ${II} -d ${FIRSTDAY}:" | ruby ${OOD_BASE_DIR}/misc/resource_info.rb > ${FILE_U}
	      fi

	      if [ $? -ne 0 ]; then
                rm ${LOCKFILE} ${GROUP_TMP}
                exit 1
	      fi
	      
              if [ -s ${FILE_U} ]; then
                chmod 640 ${FILE_U}
                chown root:${II} ${FILE_U}
              else
                rm -f ${FILE_U}
              fi
	    fi
	} &
	wait
    done

    rm ${GROUP_TMP}
}

#==============================================================================
# HOME領域 (容量)
#==============================================================================
{
    # 各ユーザのホームディレクトリのファイル容量を獲得
    su - ktool -c "${REMOTE_SSH} ${ACCOUNTD} -l -c" | tr -d '"' | egrep '^USER' | egrep -v '^USER_H' > ${DISK_TMP}

    # 上コマンドが失敗した時、ファイルがない時、中身が空の時にスクリプトを終了する
    if [ $? -ne 0 -o ! -e ${DISK_TMP} -o ! -s ${DISK_TMP} ]; then
        rm -f ${LOCKFILE} ${DISK_TMP}
        exit 1
    fi

    # ファイルを一般ユーザが閲覧できないようにする
    chmod 600 ${DISK_TMP}
    chown root:root ${DISK_TMP}

    while read -r line; do
        user=`echo $line | awk -F, '{print $2}'`
	FILE=${HOME_DIR}/${user}.disk
        echo "$line" > ${FILE}
	chmod 600 ${FILE}
        chown ${user} ${FILE}
    done < ${DISK_TMP}

    rm ${DISK_TMP}
} &

#==============================================================================
# HOME領域 (inode)
#==============================================================================
{
    # 各ユーザのホームディレクトリのinodeを獲得
    su - ktool -c "${REMOTE_SSH} ${ACCOUNTD} -l -i -c" | tr -d '"' | egrep '^USER' | egrep -v '^USER_H' > ${INODE_TMP}

    # 上コマンドが失敗した時、ファイルがない時、中身が空の時にスクリプトを終了する
    if [ $? -ne 0 -o ! -e ${INODE_TMP} -o ! -s ${INODE_TMP} ]; then
        rm -f ${LOCKFILE} ${INODE_TMP}
        exit 1
    fi

    # ファイルを一般ユーザが閲覧できないようにする
    chmod 600 ${INODE_TMP}
    chown root:root ${INODE_TMP}

    while read -r line; do
        user=`echo $line | awk -F, '{print $2}'`
	FILE=${HOME_DIR}/${user}.inode
        echo "$line" > ${FILE}
	chmod 600 ${FILE}
	chown ${user} ${FILE}
    done < ${INODE_TMP}

    rm ${INODE_TMP}
} &

#==============================================================================
# 終了処理
#==============================================================================
wait
date "+%Y/%m/%d %H:%M:%S (JST)" > ${DATE_TXT}
echo ${SECONDS} > ${ELAPSED_TIME}
rm ${LOCKFILE}
