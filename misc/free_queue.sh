#!/usr/bin/env bash

GROUP=$1
CMD="/usr/local/bin/pjstat --rsc -g $GROUP | grep small-free | wc -l"
if [ "$HOSTNAME" = "fn06sv04" ]; then
    eval ${CMD}
else
    ssh login.fugaku.r-ccs.riken.jp ${CMD}
fi
