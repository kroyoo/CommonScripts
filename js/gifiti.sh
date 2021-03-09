#!/usr/bin/env bash

DAY=$(date +%d)
numDay=$(date +%-d)
MONTH=$(date +%m)
YEAR=$(date +%C%y)
beg=3
end=19

function getMonthSum(){
    # 闰年判断
    if [ $((${YEAR}%4)) -eq 0 ]&&[ $((${YEAR}%100)) -ne 0 ]||[ $((${YEAR}%400)) -eq 0 ]
    then
        # 闰年月份天数
        MonthSum="31 29 31 30 31 30 31 31 30 31 30 31"
    else
        # 非闰年月份天数
        MonthSum="31 28 31 30 31 30 31 31 30 31 30 31"
    fi

    # 非闰年月份天数
    #MonthSum="31 28 31 30 31 30 31 31 30 31 30 31"
    echo "$MonthSum" | awk '{print $'"${1}"'}'
}



function isLeap(){
    if ((${YEAR}%400==0));then
       echo "${YEAR}: 闰年"
    elif ((${YEAR}%4==0));then
       echo "${YEAR}: 闰年"
    else
       echo "${YEAR}: 平年"
    fi
}

#isLeap ${YEAR}
DAYSUM=`getMonthSum ${MONTH}`

echo "$DAYSUM"

for((i=1;i<=$numDay;i++));
do
    #rd=$(( $i % 13 + 3 ))
    #[bed,end]
    rd=$((RANDOM % ($end - $beg) + $beg))
    if [[ $i -le 9 ]]; then
        for((j=1;j<=$rd;j++));
        do
            DATES="${YEAR}""-""${MONTH}""-0""${i}""T12:""$(( $j % 9 + 10 ))"":""$(( $j * 3 + 7 ))"
            echo $DATES
        done
    else
        for((j=1;j<=$rd;j++));
        do
            DATES="${YEAR}""-""${MONTH}""-""${i}""T12:""$(( $j % 9 + 13 ))"":$(( $j * 3 + 7 ))"
            echo $DATES
        done
    fi
done
