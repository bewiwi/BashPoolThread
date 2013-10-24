describe "BT integration test"

before()
{
    source ./BT.sh
    rm -f "$(__getPoolFile)"*
}

it_test_add_and_list()
{
    source ./BT.sh
    BTpoolNew test 12
    BTpoolNew prout 2
    BTpoolNew flag 5

    test $(BTpoolList | wc -l) = 3
}

it_test_add_and_remove()
{
    source ./BT.sh
    BTpoolNew test 12
    BTpoolNew prout 2
    BTpoolNew flag 5
    
    BTpoolRemove prout
    BTpoolRemove test

    test $(BTpoolList | wc -l) = 1 
}

it_test_pool_exist()
{
    source ./BT.sh
    BTpoolNew pool1 2
    BTpoolNew pool2 34
    BTpoolNew pool3 23

    BTpoolExist pool1
    BTpoolExist pool2
    BTpoolExist pool3
}

it_test_pool_not_exist()
{
    source ./BT.sh
    BTpoolNew pool1 2
    BTpoolNew pool2 34

    test "$(BTpoolExist test ; echo $?)" = 1
}

it_test_add_and_list_command()
{
    source ./BT.sh
    BTpoolNew test 12

    BTcommandAdd test ls
    BTcommandAdd test echo test

    test $(BTcommandList test | wc -l) = 2 
}

nit_test_a_simple_command()
{
    source ./BT.sh
    file=/tmp/testBT

    rm $file -f | true
    test ! -f $file

    BTpoolNew test 2
    BTcommandAdd test touch $file
    BTpoolStart test
    BTpoolWait test
    test -f $file
}

nit_test_multiple_command()
{
    source ./BT.sh
    file=/tmp/testBT

    rm ${file}{2,3,4,5} -f | true
    test ! -f ${file}2
    test ! -f ${file}3
    test ! -f ${file}4
    test ! -f ${file}5

    BTpoolNew test 2
    BTcommandAdd test sleep 1
    BTcommandAdd test "sleep 1; touch ${file}2"
    BTcommandAdd test "sleep 1; touch ${file}3"
    BTcommandAdd test "sleep 1; touch ${file}4"
    BTcommandAdd test "sleep 1; touch ${file}5"

    BTpoolStart test
    BTpoolWait test

    test  -f ${file}2
    test  -f ${file}3
    test  -f ${file}4
    test  -f ${file}5
}

nit_test_multiple_command2()
{
    source ./BT.sh

    file=/tmp/testBT
    rm ${file} -f | true

    BTpoolNew test 2
    BTcommandAdd test "echo 1 >> $file"
    BTcommandAdd test "sleep 2;echo 2 >> $file"
    BTcommandAdd test "echo 3 >> $file"
    BTcommandAdd test "echo 4 >> $file"
    BTcommandAdd test "echo 5 >> $file"

    BTpoolStart test
    BTpoolWait test

    test  -f ${file}

    test "$(cat $file | sort | tr -d '\n')" = "12345"

}
