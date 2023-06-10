# Open OnDemand apps for the supercomputer Fugaku

This repository contains local customizations and singularity recipes of [Open OnDemand](https://openondemand.org/) applications used on [Fugaku](https://www.r-ccs.riken.jp).

* misc/create_web.sh
This script creates a graph containing monthly usage counts for interactive applications.
The graph can be viewed at https://(IP ADDRESS)/public/ana.html.

* MEMO
Run the following commands to make the icon visible only to specific users

# chmod 750 Vampir MATLAB Gaussian GaussView
# chgrp isv001 Vampir
# chgrp isv002 MATLAB
# chgrp isv003 Gaussian GaussView
