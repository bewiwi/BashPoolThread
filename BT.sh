#!/bin/bash
#Dépendance
#grep awk sort

declare -A BashThreadPoolNumber
declare -A BashThreadPoolPID
declare -A BashThreadPoolCommand

BTsleepLoop=0.4

###### SYS Function #####

#$1 : array
#$2 : name
function __getLastIndex()
{
    array=$1
    name=$2
    index=${!array[@]} | grep "^$name," | awk -F',' 'END {print $2}'
    [ -z $index ] && index=0
    echo -n $index
}

#$1 : name
function __countAndCheckPID()
{
    name=$1
    i=0
    NewPoolId=""
    for PID in ${BashThreadPoolPID[$name]}
    do
        if [ -d /proc/$PID  ] ; then
            NewPoolId="$NewPoolId $PID"
            (( i++ ))
        fi
    done
    BashThreadPoolPID[$name]=$NewPoolId
    echo $i
}

##### User Function #####

#Pool
#$1 nameofpool
#$2 numberofThread
function BTpoolNew()
{
    name=$1


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

    numberofThread=$2
    BashThreadPoolNumber[$name]=$numberofThread
    BashThreadPoolPID[$name]=''
}

#$1 nameofpool
function BTpoolRemove()
{
    name=$1
    BTpoolExist $name || return 1
    unset BashThreadPoolNumber[$name]
    for index in  "${!BashThreadPoolCommand[@]}"
    do
        echo $index | grep "^$name," || continue
        unset BashThreadPoolCommand[$index]
    done

    unset BashThreadPoolPID[$name]


}

#$1 nameofpool
function BTpoolExist()
{
    if [  -z "${BashThreadPoolNumber[$1]}" ]
    then
        echo "Pool Doesn't exist" >&2
        return 1
    fi
    return 0
}

function BTpoolList()
{
    for name in "${!BashThreadPoolNumber[@]}"
    do
        echo "$name "${BashThreadPoolNumber[$name]}
    done
}

#$1 poolname
#$@ command 
function BTcommandAdd()
{
    name=$1
    BTpoolExist $name || return 1
    shift
    index=$(__getLastIndex $BashThreadPoolCommand $name)
    (( index++ )) || true
    BashThreadPoolCommand[$name,$index]="$@"
}

#$1 poolname
function BTcommandList()
{
    name=$1
    BTpoolExist $name || return 1

    ret="" 
    for index in  "${!BashThreadPoolCommand[@]}"
    do
        echo $index | grep "^$name," > /dev/null 2>&1 || continue
        id=$(echo $index | sed "s/^$name,//g")
        ret+="$id  ${BashThreadPoolCommand[$index]}\n"
    done
    echo -e -n "$ret"
}

#$1 poolname
function BTpoolStart()
{
    name=$1
    BTpoolExist $name || return 1
   
    ret="" 
    for index in  "${!BashThreadPoolCommand[@]}"
    do
        command="${BashThreadPoolCommand[$index]}"
        bash -c "$command" &
        PID=$!
        BashThreadPoolPID[$name]="${BashThreadPoolPID[$name]} $PID"

        NUM=$(__countAndCheckPID $name)
        
        #loop wainting a new sloot
        while [ $NUM -ge ${BashThreadPoolNumber[$name]} ]
        do
            NUM=$(__countAndCheckPID $name)
            sleep $BTsleepLoop 
        done
    done
}

#$1 : poolname
function BTpoolWait()
{
    name=$1
    BTpoolExist $name || return 1

    #Wait the last thread
    for PID in ${BashThreadPoolPID[$name]}
    do
        wait $PID || true
    done
}


#$1 : poolname
function BTpoolStop()
{
    name=$1
    BTpoolExist $name || return 1
    
    for PID in  ${BashThreadPoolPID[$name]}
    do
        kill $PID || true
        [ -d /proc/$PID  ] && continue
        sleep 1
        [ -d /proc/$PID  ] ||  kill -9 $PID
    done
}
