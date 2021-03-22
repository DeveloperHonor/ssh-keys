#!/bin/bash
 
#Define Current Directory 
CURRENT_DIR=$(cd "$(dirname $0)";pwd)

#Define Toplevel Directory
TOPLEVEL_DIR=$(cd ${CURRENT_DIR}/..;pwd)

IPLIST=$(cat ${CURRENT_DIR}/iplist)
if [ $# -ne 2 ];then
    echo "Usage:sh $0 用户名 密码"
    exit 99
fi
USER=$1
PASSWD=$2

rm -rf ${CURRENT_DIR}/ssh/
rm -f authorized_keys

for ip in $IPLIST;do
    mkdir -p ${CURRENT_DIR}/ssh/${ip}

#删除已存在的id_rsa.pub
/usr/bin/expect <<EOF
    spawn ssh ${USER}@${ip} rm -f ~/.ssh/*
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*password*" { send "${PASSWD}\r";exp_continue}
    }
#每台服务器生成 rsa 加密文件
    spawn ssh ${USER}@${ip} ssh-keygen -t rsa
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*password*" { send "${PASSWD}\r";exp_continue}
        "Overwrite*" { send "y\r";exp_continue}
        "Enter file in which to save the key*" { send "\r"; exp_continue}
        "Enter passphrase*" { send "\r";exp_continue }
        "Enter same passphrase again*" { send "\r"; exp_continue }
    }
#将每台服务器的id_rsa.pub文件放置于独立的文件夹
    spawn scp ${USER}@${ip}:~/.ssh/id_rsa.pub ${CURRENT_DIR}/ssh/${ip}/
    expect {
        "*yes/no*" { send "yes\r";exp_continue}
        "*password*" { send "${PASSWD}\r";exp_continue}
    }
EOF
done


#将所有的 id_rsa.pub 放置到 authorized_keys中
for ip in $IPLIST;do
    cat ${CURRENT_DIR}/ssh/${ip}/id_rsa.pub >> ${CURRENT_DIR}/authorized_keys
    chmod 600 ${CURRENT_DIR}/authorized_keys
done

#将 authorized_keys 放入到 每台服务器主机的 ~/.ssh/目录下
for ip in $IPLIST;do
/usr/bin/expect <<EOF
    spawn scp ${CURRENT_DIR}/authorized_keys ${ip}:~/.ssh/
    expect {
        "*yes/no*" { send "yes\r";exp_continue}
        "*password*" { send "${PASSWD}\r";exp_continue}
    }
EOF
done


#测试连接避免提示符出现
for ip in $IPLIST;do
/usr/bin/expect <<EOF
    spawn ssh ${ip} date
    expect {
        "*yes/no*" { send "yes\r";exp_continue }
        "*password*" { send "${PASSWD}\r";exp_continue}
    }
EOF
done

cat > ${CURRENT_DIR}/remote_ssh<<eof
IPLIST="$(echo $(cat ${CURRENT_DIR}/iplist))"
for ip in \${IPLIST} ;do
USER=\$(whoami)
/usr/bin/expect <<EOF
        spawn ssh \${USER}@\${ip} date
        expect {
                "*yes/no*" { send "yes\r";exp_continue}
                "*password*" { send "${PASSWD}\r"; exp_continue}
        }
EOF
done
eof


#拷贝执行脚本
for ip in $IPLIST;do
        scp ./remote_ssh  $ip:~/
/usr/bin/expect <<EOF
        spawn ssh ${USER}@${ip} sh ~/remote_ssh
        expect {
                "*yes/no*" { send "yes\r";exp_continue}
                "*password*" { send "${PASSWD}\r"; exp_continue}
        }
EOF
done
