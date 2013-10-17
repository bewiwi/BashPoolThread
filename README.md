BashPoolThread
==============
BashPoolThread is a little script which provides some functions to control pools of background command

### Installation
No installation is needed just download BT.sh or clone git repo and source the script to access to the function

```
source ./BT.sh
```

OR

```
. ./BT.sh
```

### Usage
BT.sh provides some public functions :
BTpoolNew poolname number
> Add a new pool with name 'poolname' and 'number' workers

BTpoolStart poolname
> Start pool 'poolname'. It start to execute command and wait new command

BTpoolStop poolname
> Stop pool 'poolname'

BTpoolWait poolname
> Wait pool 'poolname' has an empty command list

BTpoolList
> List all pool created

BTcommandAdd poolname command
> Add a new command in 'poolname'

BTcommandList poolname
> List all command of pool 'poolname'

### How it works ?
BT.sh needs one file for any pool and juste modify this file to control the pool.
(Default folder : /dev/shm)

### Contribution
All contribution are welcome.
