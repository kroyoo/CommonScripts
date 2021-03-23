cd /root/tg
echo "Hello World" > /root/outlog.txt
date >> /root/outlog.txt
while :
do
        mysql -ue5sub -pe5sub -e "select version();" >>/root/outlog.txt 2>&1
        if [ $? -eq 0 ];then
                echo "mysqld running"  >> /root/outlog.txt
                break
        else
                echo "no start,sleep 5 second" >> /root/outlog.txt
                sleep 5
        fi
done
echo "while break" >> /root/outlog.txt
date >> /root/outlog.txt
#screen -S E5SubBot
#cd /root/tg
date >> /root/start.txt
./E5SubBot >>/root/start.txt 2>&1