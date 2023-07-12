#!/usr/bin/bash
#=============================================================================
ACCOUNTING_DIR=/system/ood/accounting
LOCKFILE=${ACCOUNTING_DIR}/lockfile
ELAPSED_TIME=${ACCOUNTING_DIR}/elapsed_time.txt
DATE_TXT=${ACCOUNTING_DIR}/date.txt
GROUP_DIR=${ACCOUNTING_DIR}/group
HOME_DIR=${ACCOUNTING_DIR}/home
GROUP_TMP=${GROUP_DIR}/group.tmp
DISK_TMP=${HOME_DIR}/disk.tmp
INODE_TMP=${HOME_DIR}/inode.tmp
FREE_QUEUE_TMP=${ACCOUNTING_DIR}/free_queue.tmp

#=============================================================================
ACCOUNTJ="/usr/local/bin/accountj"
ACCOUNTD="/usr/local/bin/accountd"
CHKLOWPRIORITY="/usr/local/bin/chklowpriority"
REMOTE_SSH=""
[ "$HOSTNAME" != "fn06sv04" ] && REMOTE_SSH="ssh login"
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
	{
	    # グループ名1つ1つに対してaccountj -gを実行し、グループ毎のバジェットを取得
	    FILE=${GROUP_DIR}/${II}.resource
	    su - ktool -c "${REMOTE_SSH} ${ACCOUNTJ} -g ${II} -c -h -r 1" | tr -d '"' | egrep '^SUBTHEME|^SUBTHEMEPERIOD' > ${FILE}
	    
	    if [ $? -ne 0 ]; then
		rm ${LOCKFILE} ${GROUP_TMP}
		exit 1
	    fi
	    chmod 640 ${FILE}
	    chown root:${II} ${FILE}
	} &
	
	{
	    # グループ名1つ1つに対してaccountd -gを実行し、グループ毎のディスク使用量を取得
	    # -Eをつけると、/dataと/shareの情報も出力される
	    FILE=${GROUP_DIR}/${II}.disk
	    su - ktool -c "${REMOTE_SSH} ${ACCOUNTD} -g ${II} -c -E" | tr -d '"' | tail -n +5 > ${FILE}
	    
	    if [ $? -ne 0 ]; then
		rm ${LOCKFILE} ${GROUP_TMP}
		exit 1
	    fi
	    chmod 640 ${FILE}
	    chown root:${II} ${FILE}
	} &

	{
	    # グループ名1つ1つに対してaccountd -g -iを実行し、グループ毎のi-node使用量を取得
	    FILE=${GROUP_DIR}/${II}.inode
	    su - ktool -c "${REMOTE_SSH} ${ACCOUNTD} -g ${II} -i -c" | tr -d '"' | tail -n +4 > ${FILE}
	    
	    if [ $? -ne 0 ]; then
		rm ${LOCKFILE} ${GROUP_TMP}
		exit 1
	    fi
	    chmod 640 ${FILE}
	    chown root:${II} ${FILE}
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
# 低優先度キュー
#==============================================================================
{
    # グループが低優先度キューを利用しているかどうかを調べる
    su - ktool -c "${REMOTE_SSH} ${CHKLOWPRIORITY} -a -c" | tr -d '"' | tail -n +2 > ${FREE_QUEUE_TMP}
    
    # 上コマンドが失敗した時、ファイルがない時、中身が空の時にスクリプトを終了する
    if [ $? -ne 0 -o ! -e ${FREE_QUEUE_TMP} -o ! -s ${FREE_QUEUE_TMP} ]; then
	rm -f ${LOCKFILE} ${FREE_QUEUE_TMP}
	exit 1
    fi
    
    # ファイルを一般ユーザが閲覧できないようにする
    chown root:root ${FREE_QUEUE_TMP}
    chmod 600 ${FREE_QUEUE_TMP}
    
    while read -r line; do
	group=`echo $line | awk -F, '{print $3}'`
	echo "$line" | awk -F, '{print $8}' > ${GROUP_DIR}/${group}.free_queue
	chmod 640 ${GROUP_DIR}/${group}.free_queue
	chown root:${group} ${GROUP_DIR}/${group}.free_queue
    done < ${FREE_QUEUE_TMP}

    rm ${FREE_QUEUE_TMP}
} &

wait
#==============================================================================
# 終了処理
#==============================================================================
date "+%Y/%m/%d %H:%M:%S (JST)" > ${DATE_TXT}
echo ${SECONDS} > ${ELAPSED_TIME}
rm ${LOCKFILE}
