#!/usr/bin/env bash

if [ ${#} -ne 1 ];then
        exit 1;
fi

port=$1
if [ ${port} -ge 0 ] >>/dev/null 2>&1;then
        echo "number"
else
        echo "err"
        exit 1
fi
/usr/bin/java -jar /software/java/xxxxx-0.0.1-beta.jar --server.port=${port}
