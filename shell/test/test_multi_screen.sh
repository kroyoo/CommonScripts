#!/usr/bin/env bash

start_by_screen(){
        local screen_name=$1
        local port=$2
        echo ${port}
        screen -dmS $screen_name
        cmd=$"bash start_multi_screen.sh ${port}";
        screen -x -S $screen_name -p 0 -X stuff "$cmd"
        screen -x -S $screen_name -p 0 -X stuff $'\n'
}
if [ ${#} -ne 2 ];then
        echo "args wrong"
        exit 1;
fi

count=$1
sn=$2

if [ ${count} -gt 50 ];then
        exit 1
fi

for((i=1;i<=${count};i++))
do
        start_by_screen $sn$i `expr 22330 + $i`
done
