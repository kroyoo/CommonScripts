# !/bin/bash                # 指定shell类型
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 检查Gclone
function gclone_install()
{
    gclone --version
    if [ $? -eq  0 ]; then
        echo -e "\033[32m检查到Gclone已安装!\033[0m"
    else
        echo -e "\n|  Gclone is installing ... "
        bash <(wget -qO- https://git.io/gclone.sh)
    fi
}

function check() {
    source /etc/os-release
    case $ID in
    debian|ubuntu|devuan)
        #sudo apt-get -y update && apt-get -y upgrade
        sudo apt-get -y install wget curl unzip screen fuse
        ;;
    ol|centos|fedora|rhel)
        sudo yum -y install epel-release
        sudo yum -y install wget curl unzip screen fuse fuse-devel
        ;;
    *)
        exit 1
        ;;
    esac
}


# 设置变量
setting(){
    # 设置服务名称后缀
    echo -e "=================================================================="
    echo -e "|  本脚本用于生成 gclone 自定义挂载服务"
    echo -e "=================================================================="
    echo -e ""
    drivename=''
    servicename=''
    echo -e "\033[33m输入 gclone 配置文件中，待挂载云盘名称：\033[0m"
    read -p "> " drivename
    while [ ! -n "$drivename" ]
    do
        read -p "> " drivename
    done
    #echo "-   需要挂载的云盘名称为： $drivename"
    servicename="gclone-$drivename"

    # 设置挂载点路径
    #echo -e "|   设置挂载点路径"
    path=''
    echo -e "\033[33m输入挂载路径：\033[0m"
    while [ ! -n "$path" ]
    do
        read -p "> " path
    done
    #echo "-   挂载点路径为： $path"

    # 确认挂载配置
    clear
    echo -e "=================================================================="
    echo -e "  请您确认服务配置信息"
    echo -e "> 云盘名称： \033[32m$drivename\033[0m"
    echo -e "> 挂载路径： \033[32m$path\033[0m"
    echo -e "=================================================================="
    echo -e ""
    echo -e "即将为您生成挂载服务 \033[32m$servicename\033[0m"
    echo -e ""
    go=''
    echo -e "\033[33m请确认您的配置：(y/n)\033[0m"
    while [ "$go" != 'y' ] && [ "$go" != 'n' ]
    do
        read -p "> " go;
    done

    if [ "$go" == 'n' ];then
        echo -e "\033[33m操作被中止，您是否要配置新的挂载服务？(y/n)\033[0m"
        #exit
        restart=''
        while [ "$restart" != 'y' ] && [ "$restart" != 'n' ]
        do
                read -p "> " restart;
        done
        if [ "$restart" == 'y' ];then
            clear
            servicename=''
            drivename=''
            path=''
            setting
        else
            exit
        fi
    fi

    if [ "$go" == 'y' ];then
        go=''
        config_Service
    fi
}

# 配置服务项
config_Service(){
echo -e "|  生成挂载目录"
mkdir -p $path
##### gclone-custem.service #####
# 写入 gclone-custem.service 服务
echo -e "|  生成服务配置文件：\033[32m/etc/systemd/system/$servicename.service\033[0m"
cat > /etc/systemd/system/$servicename.service <<EOF
[Unit]
Description = gclone mount for $servicename
AssertPathIsDirectory="$path"
Wants=network-online.target
After=network-online.target

[Service]
Type=notify
KillMode=none
Restart=on-failure
RestartSec=5
User=root
ExecStart = /usr/bin/gclone mount $drivename: "$path" \
--umask 000 \
--allow-other \
--allow-non-empty \
--use-mmap \
--daemon-timeout=10m \
--dir-cache-time 24h \
--poll-interval 1h \
--vfs-cache-mode writes \
--vfs-cache-max-age 24h \
--vfs-cache-max-size 4G \
--cache-dir=/tmp/vfs_cache \
--buffer-size 256M \
--vfs-read-chunk-size 80M \
--vfs-read-chunk-size-limit 1G \
--transfers 8 \
--low-level-retries 200 \
--log-level INFO \
--log-file=/home/gclone.log
ExecStop=/bin/fusermount -u "$path"
Restart=on-abort
[Install]
WantedBy = multi-user.target
EOF

echo -e "|  启动服务 $servicename ... "
# 设置文件权限
systemctl daemon-reload
systemctl enable $servicename
systemctl start $servicename.service
echo -e "=================================================================="
echo -e "\033[32m  恭喜！云盘挂载完成！\033[0m"
echo -e "=================================================================="
echo -e ""
# 检查服务状态：
#systemctl status $servicename.service
if systemctl is-active $servicename &>/dev/null ;then
        echo -e "\033[32m$servicename 服务已启动！\033[0m"
else
        echo -e "\033[33m$servicename 服务异常！\033[0m"
fi

echo -e ""
echo -e "=================================================================="
echo -e ""
echo -e "  如果此后发生云盘挂载异常，可运行以下命令重新挂载："
echo -e "  systemctl restart $servicename.service"
echo -e ""
echo -e "=================================================================="
echo -e "\033[33m您是否要配置新的挂载服务？(y/n)\033[0m"
echo -e "=================================================================="
echo -e ""
restart=''
while [ "$restart" != 'y' ] && [ "$restart" != 'n' ]
do
        read -p "> " restart;
done
if [ "$restart" == 'y' ];then
    clear
    servicename=''
    drivename=''
    path=''
    setting
else
    exit
fi
}


# 安装依赖组件
check

clear
echo -e "=================================================================="
echo -e "|  本脚本用于生成 gclone 自定义挂载服务"
echo -e "=================================================================="

# 安装Gclone
gclone_install
# 设置变量
setting
