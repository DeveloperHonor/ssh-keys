#!/bin/bash
 
#Define Current Directory 
CURRENT_DIR=$(cd "$(dirname $0)";pwd)

#Define Toplevel Directory
TOPLEVEL_DIR=$(cd ${CURRENT_DIR}/..;pwd)

if [ $# -ne 2 ];then
	echo "Usage:sh $0 用户名 密码"
	exit 99
fi
USER=$1
PASSWD=$2

rm -rf ${CURRENT_DIR}/ssh/
rm -f ~/.ssh/{authorized_keys,id_rsa,id_rsa.pub,known_hosts}

ip=""
for ip in $(cat ${CURRENT_DIR}/iplist);do
mkdir -p ${CURRENT_DIR}/ssh/${ip}

#删除已存在的id_rsa.pub
/usr/bin/expect <<EOF
	set timeout 1
	spawn ssh ${USER}@${ip} rm -f ~/.ssh/*
	expect {
		"*yes/no*" { send "yes\r";exp_continue }
		"*password*" { send "${PASSWD}\r";exp_continue}
	}
EOF
done

ip=""
#生成 id_rsa.pub
for ip in $(cat ${CURRENT_DIR}/iplist);do
/usr/bin/expect <<EOF
	set timeout 1
	spawn ssh ${USER}@${ip} ssh-keygen -t rsa
	expect {
		"*yes/no*" { send "yes\r";exp_continue }
		"*password*" { send "${PASSWD}\r";exp_continue}
		"Overwrite*" { send "y\r";exp_continue}
		"Enter file in which to save the key*" { send "\r"; exp_continue }
		"Enter passphrase*" { send "\r";exp_continue }
		"Enter same passphrase again*" { send "\r"; exp_continue }
	}	
EOF
done


#将所有的id_rsa.pub 拷贝在临时目录下 ./ssh/$ip
ip=""
for ip in $(cat ${CURRENT_DIR}/iplist);do
/usr/bin/expect <<EOF
	set timeout 1 
	spawn scp ${USER}@${ip}:~/.ssh/id_rsa.pub ${CURRENT_DIR}/ssh/${ip}/
	expect {
		"*yes/no*" { send "yes\r";exp_continue }
		"*password*" { send "${PASSWD}\r";exp_continue}
	}
EOF
done

#将所有的 id_rsa.pub 放置到 authorized_keys中
ip=""
for ip in $(cat ${CURRENT_DIR}/iplist);do
	cat ${CURRENT_DIR}/ssh/${ip}/id_rsa.pub >> ${CURRENT_DIR}/authorized_keys
	chmod 600 ${CURRENT_DIR}/authorized_keys
done

#将 authorized_keys 放入到 每台服务器主机的 ~/.ssh/目录下
ip=""
for ip in $(cat ${CURRENT_DIR}/iplist);do
/usr/bin/expect <<EOF
	set timeout 1 
	spawn scp ${CURRENT_DIR}/authorized_keys ${ip}:~/.ssh/
	expect {
		"*yes/no*" { send "yes\r";exp_continue }
		"*password*" { send "${PASSWD}\r"; exp_continue}
	}
EOF
done


#测试连接避免提示符出现
ip=""
for ip in $(cat ${CURRENT_DIR}/iplist);do
/usr/bin/expect <<EOF
	set timeout 1 
	spawn ssh ${ip} date
	expect {
		"*yes/no*" { send "yes\r";exp_continue }
		"*password*" { send "${PASSWD}\r";exp_continue }
	}
EOF
done


cat > ${CURRENT_DIR}/remote_ssh<<eof
IPLIST="`awk -F "+" '{for(i=1;i<=NF;i++) a[i,NR]=$i}END{for(i=1;i<=NF;i++) {for(j=1;j<=NR;j++) printf a[i,j] " ";print ""}}' iplist`"
for ip in \${IPLIST} ;do
USER=\$(whoami)
/usr/bin/expect <<EOF
        spawn ssh \${USER}@\${ip} date
        expect {
                "*yes/no*" { send "yes\r";exp_continue}
        }
EOF
done
eof

sleep 2

for ip in $(cat ${CURRENT_DIR}/iplist);do
        scp ./remote_ssh  $ip:~/
done

for ip in $(cat ${CURRENT_DIR}/iplist);do
        ssh $ip "sh ~/remote_ssh"
done

