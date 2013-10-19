#!/bin/bash
#Dépendance
#grep awk sort

declare -r BTworkFolder=/dev/shm/
declare -r BTsleepLoop=0.4

###### SYS Function #####

#$1 : poolname
function __getPoolFile()
{
    local name=$1
    echo "$BTworkFolder/BT$(id -u)-$name"
}

#$1 : file
function __checkFile()
{
    local file=$1
    if [ ! -e $file ];then
        echo "File not exist : $file" >&2
        return 1
    fi
    if [ ! -w $file ];then
        echo "File not writable : $file" >&2
        return 1
    fi

    i=0
    while read line
    do
        (( i++ ))
        #First line 
       if [[ $i = 0  ]] && [ $line =~ ^#[0-9][0-9 ]*:[0-9]*$ ]
       then
            echo "Invalid First line" >&2
            return 1
       fi
    done < $file
}

#$1 : name
function __getPoolNumberOfThread()
{
    local name=$1
    local file="$(__getPoolFile $name)"
    local number=$(sed q "$file" | sed -e 's/^#\([0-9]*\):.*$/\1/g' )
    echo $number
}

#$1 : name
function __getPoolPids()
{
    local name=$1
    local file="$(__getPoolFile $name)"
    echo $(sed 1d "$file" | sed 's/:.*$//g' )
}

#$1 : name
#$2 : pid
function __removePoolPid()
{
    local name=$1
    local PID=$2
    local file="$(__getPoolFile $name)"
    sed -i "/^$PID:.*$/d" "$file"
}

#$1 : name
#$2 : PID
#$3 : command
function __setPidToCommand()
{
    local name=$1
    local PID=$2
    local command="$3"
    local file="$(__getPoolFile $name)"
    local escapedCommand="`echo $command | sed -e 's/[]\/()$*.^|[]/\\\\&/g'`"
    sed -i "s/^:$escapedCommand$/$PID&/" "$file" 

}

#$1 : name
function __countAndCheckPID()
{
    local name=$1
    local i=0
    local NewPoolId=""
    for PID in $(__getPoolPids $name)
    do
        if [ ! -d /proc/$PID  ] ; then
            __removePoolPid $name $PID
            continue
        fi
        (( i++ ))
    done
    echo $i
}


#$1 : name
function __getNextPoolCommand()
{
    local name=$1
    local file="$(__getPoolFile $name)"
    local ret=$( sed  1d "$file")
    ret=$(echo "$ret" | sed '/^[0-9][0-9]*:/d')
    ret=$(echo "$ret" | sed 's/^://g') 
    echo "$ret" | sed q
}

#$1 : name
function __startPool()
{
    local name=$1
    local NumberMax=$(__getPoolNumberOfThread $name)
    
    __setPidToPool "$name" "$$"
    while [ -f "$( __getPoolFile $name )" ]
    do
        command="$( __getNextPoolCommand $name)" 
        if [ -z "$command" ];then
            sleep $BTsleepLoop
            continue
        fi
        bash -c "$command" &
        PID=$!
        __setPidToCommand "$name" "$PID" "$command"
        NUM=$(__countAndCheckPID $name)
        
        #loop wainting a new sloot
        while [ "$NUM" -ge "$NumberMax" ]
        do
            NUM=$(__countAndCheckPID $name)
            sleep $BTsleepLoop 
        done
    done

}

#$1 : name
#$2 : pid
function __setPidToPool()
{
    local name=$1
    local PID=$2
    local file="$(__getPoolFile $name)"
    sed -i "s/^#[0-9][0-9]*:/&$PID/" "$file" 
}

##### User Function #####

#Pool
#$1 nameofpool
#$2 numberofThread
function BTpoolNew()
{
    local name=$1

    if [[ ! -z $2 && $2 =~ ^[0-9]*$ ]];then
        true
    else
        echo "number of thread is not an int : $2" >&2
        return 1
    fi

    if [[ ! "$name" =~ ^[a-zA-Z0-9]*$ ]];then
        echo "Only Alphanumeric Char allowed : $name" >&2
        return 1
    fi
    
    #TODO Check File exist

    local numberofThread=$2
    echo "#$numberofThread:" > "$(__getPoolFile $name)"
}

#$1 nameofpool
function BTpoolRemove()
{
    local name=$1
    BTpoolExist $name || return 1
    rm -f "$(__getPoolFile $name)"
}

#$1 nameofpool
function BTpoolExist()
{
    local name=$1
    if [ ! -w "$(__getPoolFile $name)" ]
    then
        echo "Pool Doesn't exist" >&2
        return 1
    fi
    return 0
}

function BTpoolList()
{
    for file in "$(__getPoolFile)"*
    do
        echo "$(basename $file | sed "s/BT$(id -u)-//g" )"
    done
}

#$1 poolname
#$@ command 
function BTcommandAdd()
{
    local name=$1
    BTpoolExist $name || return 1
    shift
    __checkFile "$(__getPoolFile $name)" || return 1
    echo ":$@" >> $(__getPoolFile $name )
}

#$1 poolname
function BTcommandList()
{
    local name=$1
    BTpoolExist $name || return 1

    local ret="" 
    local i=-1
    while read line
    do
        (( i++ )) || true
        [ $i = 0 ] && continue
        command=$( echo $line | sed 's/^[0-9]*://g') 
        ret+="$i $command\n"
    done < "$(__getPoolFile $name)"
    echo -e -n "$ret"
}

#$1 poolname
function BTpoolStart()
{
    local name=$1
    BTpoolExist $name || return 1
    #Daemonize
    ( __startPool $name & )
}

#$1 : poolname
function BTpoolWait()
{
    local name=$1
    BTpoolExist $name || return 1

    #Wait the last thread
    while true
    do
        [ $(__countAndCheckPID $name) = 0 ] && break
        sleep $BTsleepLoop
    done
}

#$1 : poolname
function BTpoolStop()
{
    local name=$1
    BTpoolExist $name || return 1
    rm $(__getPoolFile $name)
    
}

#Sourced
[ $# = "0" ] && exit 0

function help()
{
    cat <<EOF
$0 pool
    new|n|add|a   poolname      : Add a new pool
    remove|r|delete|d  poolname : Remove a pool
    list|l                      : List pools
    exist|e poolname            : Exitcode 0 if poolname exist
    start poolname              : Start pool
    stop poolname               : Stop pool
    wait poolname               : Wait pool
$0 command
    add|a poolname command      : Add a command to a pool
    list|l poolname             : List command of a pool
EOF
}

case "$1" in
    pool|p)
        shift
        arg=$1
        shift
        case "$arg" in
            new|n|add|a)
                BTpoolNew $@ 
                ;;
            remove|r|delete|d)
                BTpoolRemove $@
                ;;
            list|l)
                BTpoolList $@
                ;;
            exist|e)
                BTpoolExist $@
                ;;
            start)
                BTpoolStart $@
                ;;
            stop)
                BTpoolStop $@
                ;;
            wait|w)
                BTpoolWait $@
                ;;
            *)
                help
                exit 1
                ;;
        esac
        ;;
    command|c)
        shift
        arg=$1
        shift
        case "$arg" in
            add|a)
                BTcommandAdd $@
                ;;
            list|l)
                BTcommandList $@
                ;;
            *)
                help
                exit 1
                ;;
        esac
        ;;
    *)
        help
        exit 1
        ;;
esac
