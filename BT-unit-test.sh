describe "BT unit test"

before()
{
    source ./BT.sh
    rm -f "$(__getPoolFile)"*
}

#$1 : name
__createFakePoolFile()
{
    cat <<EOF >"$(__getPoolFile $1)"
#5:
12234:ls /tmp/test
2345:cat/etc/passwd
:ls /tmp/prout
EOF
}

#$1 : name
__createComplexFakePoolFile()
{
    cat <<EOF >"$(__getPoolFile $1)"
#5:
12234:ls /tmp/test
2345:cat/etc/passwd
:ls /tmp/prout
:ls /tmp/prout*
:ls /tmp/*
:ls /tmp/prout\ /*¨
:ls /tmp/prout | grep test
:ls /tmp/prout | test | touch a[1,2,3}
:echo /tmp/prout |grep test | sed 's/\s*tesT/prou*-/' | ping
EOF
}


it_test_getPoolNumberOfThread()
{
    source ./BT.sh
    BTpoolNew test 12
    BTpoolNew prout 2
    BTpoolNew flag 5

    test $(__getPoolNumberOfThread test ) = 12
    test $(__getPoolNumberOfThread prout) = 2
    test $(__getPoolNumberOfThread flag ) = 5
}

it_test_getPoolPids()
{
    source ./BT.sh
    __createFakePoolFile fake
    test "$(__getPoolPids fake | tr "\n" " " )" = "12234 2345 "
}

it_test_removePoolPid()
{
    source ./BT.sh
    __createFakePoolFile fake
    grep 2345  $(__getPoolFile fake)
    __removePoolPid fake 2345
    test "$(grep 2345  $(__getPoolFile fake) > /dev/null ; echo $?)" != "0"
}

it_test_getNextPoolCommand()
{
    source ./BT.sh
    __createFakePoolFile fake
    test "$( __getNextPoolCommand fake)" = "ls /tmp/prout"
}

it_test_setPidToCommand()
{
    source ./BT.sh
    __createFakePoolFile fake
    __setPidToCommand fake 51 "ls /tmp/prout"
    grep "51:ls /tmp/prout" $(__getPoolFile fake)
}

it_test_setPidToComplexCommand()
{
    source ./BT.sh
    __createComplexFakePoolFile fake
    command="echo /tmp/prout |grep test | sed 's/\s*tesT/prou*-/' | ping"
    __setPidToCommand fake 51 "$command"
    test $( grep "^51:" $(__getPoolFile fake) | wc -l ) = 1
}

it_test_setPidToComplexCommand2()
{
    source ./BT.sh
    __createComplexFakePoolFile fake
    file=$(__getPoolFile fake)
    for i in $(seq 3 -1 1)
    do
        command="ping -c 1 ks$i.kimsufi.com 2>/dev/null | head -n 1| sed 's/.*com\ (\([0-9.]*\)).*/\1/g' >> ~/hack/kimsufi/ip.txt" 
        echo -e ":$command" >> $file
        __setPidToCommand fake $(( 51 + $i )) "$command"
        test $( grep "^$(( 51 + $i )):" $(__getPoolFile fake)| wc -l ) = 1
    done
}

it_test_setPidToPool()
{
    source ./BT.sh
    __createFakePoolFile fake
    __setPidToPool fake 34
    test   "$( cat $(__getPoolFile fake) |head -n 1)" = "#5:34"
}
