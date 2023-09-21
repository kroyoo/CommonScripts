#!/bin/bash

# 使用 ufw status 命令获取规则列表
rules=$(ufw status | grep "DENY" | grep -v "Anywhere (v6)" | awk '{print $1 " " $3}')

# 将结果按行分割为数组
IFS=$'\n' read -r -d '' -a rule_array <<<"$rules"

# 遍历数组
for rule in "${rule_array[@]}"; do
    # 使用空格分割每行的 To 和 From 列
    to=$(echo "$rule" | awk '{print $1}')
    from=$(echo "$rule" | awk '{print $2}')
    echo " ==================== $to From: $from ==================== "

    if [ "$to" != "Anywhere" ] && [ "$from" == "Anywhere" ]; then
        to_port=$(echo "$to" | awk -F'/' '{print $1}')
        to_proto=$(echo "$to" | awk -F'/' '{print $2}')
        proto_arg=""
        # 判断 proto 是否为空
        if [ -z "$to_proto" ]; then
            proto_arg=""
        else
            proto_arg="proto $to_proto"
        fi

        # 删除规则
        ufw delete deny to any port ${to_port} ${proto_arg}

        ufw insert 1 deny from 0.0.0.0/0 to any port ${to_port} ${proto_arg}
        ufw insert $(ufw status numbered | grep '(v6)' | grep -o '[0-9]*' | head -n 1) deny from ::/0 to any port ${to_port} ${proto_arg}

    elif
        [ "$to" == "Anywhere" ] && [ "$from" != "Anywhere" ]
    then
        ufw delete deny from ${from}
        if [[ "$from" =~ : ]]; then
            # shellcheck disable=SC2046
            ufw insert $(ufw status numbered | grep '(v6)' | grep -o '[0-9]*' | head -n 1) deny from ${from} to any port ${to}
        else
            ufw insert 1 deny from ${from}
        fi

    elif [ "$to" != "Anywhere" ] && [ "$from" != "Anywhere" ]; then
        to_port=$(echo "$to" | awk -F'/' '{print $1}')
        to_proto=$(echo "$to" | awk -F'/' '{print $2}')

        # 检查是否是IPv6地址
        if [[ "$from" =~ : ]]; then
            rule_number=$(ufw status numbered | grep '(v6)' | grep -o '[0-9]*' | head -n 1)
        else
            rule_number=1
        fi

        proto_arg=""
        # 判断 proto 是否为空
        if [ -z "$to_proto" ]; then
            proto_arg=""
        else
            proto_arg="proto $to_proto"
        fi

        # 删除规则
        ufw delete deny from ${from} to any port ${to_port} ${proto_arg}
        # 插入规则
        ufw insert $rule_number deny from ${from} to any port ${to_port} ${proto_arg}
    fi
done
