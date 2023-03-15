#!/bin/bash

CMD='accountd -E -c | grep ^\"/vol | xargs echo'
if [ "$HOSTNAME" = "fn06sv04" ]; then
    ${CMD}
else
    ssh login.fugaku.r-ccs.riken.jp ${CMD}
fi
