# Required：Executing the script you need install expect tool for all servers using yum <br>

```
you need execute command as follows on Redhat Family OS before 7 version:
yum install -y expect
or
you need execute command as follows on Redhat Family OS after 8 version:
dnf install -y expect
```

# Step 1： Configure iplist files<br>
example:
```
cat iplist
host1
host2
host3
host4
host5
host6
```
# Step2:  Executing script autoexssh.sh
```
sh autoexssh.sh usernanme password

#example:
sh autoexssh root rootpassword
```
---
<h1>Note:</h1>

```
# The expect package needs be installed when you execute the autoexssh.sh scripts for every machine
# yum install -y expect
```
