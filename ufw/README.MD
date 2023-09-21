### reorder ufw deny

```shell


#!/bin/bash

# 使用 ufw status 命令获取规则列表
rules=$(ufw status | grep "DENY" | grep -v "Anywhere (v6)" | awk '{print $1 " " $3}')

# 将结果按行分割为数组
IFS=$'\n' read -r -d '' -a rule_array <<< "$rules"

# 遍历数组
for rule in "${rule_array[@]}"; do
    # 使用空格分割每行的 To 和 From 列
    to=$(echo "$rule" | awk '{print $1}')
    from=$(echo "$rule" | awk '{print $2}')

    echo "To: $to, From: $from"

    if [ "$to" != "Anywhere" ] && [ "$from" == "Anywhere" ]; then
        ufw delete deny ${to}
        ufw insert 1 deny from 0.0.0.0/0 to any port ${to}
        ufw insert `ufw status numbered | grep '(v6)' | grep -o '[0-9]*' | head -n 1` deny from ::/0 to any port ${to}
        echo "from_anywhere"

    elif [ "$to" == "Anywhere" ] && [ "$from" != "Anywhere" ]; then
        echo "port_anywhere"
        ufw delete deny from ${from}
        if [[ "$from" =~ : ]]; then
            echo "IP地址是IPv6"
            ufw insert `ufw status numbered | grep '(v6)' | grep -o '[0-9]*' | head -n 1` deny from  ${from} to any port ${to}
        else
            echo "IP地址是IPv4"
            ufw insert 1 deny from ${from}
        fi

    elif [ "$to" != "Anywhere" ] && [ "$from" != "Anywhere" ]; then
            if [[ "$from" =~ : ]]; then
                echo "IP地址是IPv6"
                ufw delete deny from ${from} to any port ${to}
                ufw insert `ufw status numbered | grep '(v6)' | grep -o '[0-9]*' | head -n 1` deny from  ${from} to any port ${to}
            else
                echo "IP地址是IPv4"
                ufw delete deny from ${from} to any port ${to}
                ufw insert 1 deny from  ${from} to any port ${to}
            fi
    fi
done


````