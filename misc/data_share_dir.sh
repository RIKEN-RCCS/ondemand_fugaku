CMD='accountd -E -c | grep ^\"/vol | xargs echo'
ssh login.fugaku.r-ccs.riken.jp ${CMD}

