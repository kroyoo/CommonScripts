#!/usr/bin/env bash


kill_by_name(){
    local name=$1
    stop_screen ${name}
    ps -ef | grep ${name} | grep -v grep | awk '{print $2}' | xargs kill -9
}

stop_screen(){
	local name=$1

	count=$(screen -list ${name} |  grep "[0-9]\+\..*" | awk '{print $1}' | wc -l)

	for((i=1;i<=${count};i++));
	do
	    sp=$(screen -list ${name} |  grep "[0-9]\+\..*" | awk '{print $1}' | sed -n "1p")
	    screen -S ${sp} -X quit
	done

	screen -wipe >>/dev/null 2>&1

}

for i in $@
do
    kill_by_name ${i}
done
