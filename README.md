BashPoolThread
==============
BashPoolThread is a little script which provides some functions to control pools of background command

### Installation
No installation is needed just download BT.sh or clone git repo and source the script to access to the function or exec the script to access with your command line

```
source ./BT.sh
```

OR

```
./BT.sh
```

### Usage in a script ( source mode )
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

BTpoolRemove poolname
> Remove pool 'poolname'

BTcommandAdd poolname command
> Add a new command in 'poolname'

BTcommandList poolname
> List all command of pool 'poolname'

### Usage in a terminal ( CLI mode )

```
./BT.sh pool
    new|n|add|a   poolname      : Add a new pool
    remove|r|delete|d  poolname : Remove a pool
    list|l                      : List pools
    exist|e poolname            : Exitcode 0 if poolname exist
    start poolname              : Start pool
    stop poolname               : Stop pool
    wait poolname               : Wait pool
./BT.sh command
    add|a poolname command      : Add a command to a pool
    list|l poolname             : List command of a pool
```

### Example
```bash
source BT.sh

##Create a pool with 2 worker
BTpoolNew test 2

#Start pool
BTpoolStart test
>[1] 12643

for i in $(seq 1 5) ; do BTcommandAdd test touch /tmp/$i; done

ls /tmp
>1  2  3  4  5

BTpoolStop test
BTpoolRemove test

```

### How it works ?
BT.sh needs one file for any pool and juste modify this file to control the pool.
(Default folder : /dev/shm)

### Contribution
All contribution are welcome.
