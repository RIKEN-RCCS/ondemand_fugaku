# Open OnDemand for the supercomputer Fugaku

This repository contains local customizations and singularity recipes of [Open OnDemand](https://openondemand.org/) applications used on [Fugaku](https://www.r-ccs.riken.jp).

## MEMO
* Run the following commands to make the icon visible only to specific users
```
# chmod 750 Vampir MATLAB Gaussian GaussView
# chgrp isv001 Vampir
# chgrp isv002 MATLAB
# chgrp isv003 Gaussian GaussView
```
