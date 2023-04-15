#!/usr/bin/env bash

CMD='/usr/local/bin/accountd -E -c | grep ^\"/vol | xargs echo'
if [ "$HOSTNAME" = "fn06sv04" ]; then
    eval ${CMD}
else
    ssh login.fugaku.r-ccs.riken.jp ${CMD}
fi
