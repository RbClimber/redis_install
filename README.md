脚本的使用：
bash redis.sh
(执行机器需与配置节点之间建立ssh单向信任，
即执行机器能够免密码ssh访问任意配置节点)

集群功能：
运行环境：
ruby>=2.2.2

脚本执行完成后，已启动各节点，但是集群功能仍需手动启动。

集群的使用：
集群建立之后，使用以下命令使用集群：
redis-cli -c -h host -p port
eg.
[root@localhost ~]# redis-cli -c -h 172.31.108.52 -p 17001
172.31.108.52:17001> set foo bar
-> Redirected to slot [12182] located at 172.31.108.54:17003
OK
172.31.108.54:17003> exit
[root@localhost ~]# redis-cli -c -h 172.31.108.55 -p 17006
172.31.108.55:17006> get foo
-> Redirected to slot [12182] located at 172.31.108.54:17003
"bar"
172.31.108.54:17003> exit



#旧版说明删除内容
启动集群功能方法（步骤）如下：
进入任意一台redis节点服务器
step 1:
source /etc/profile
step 2:
redis-trib.rb create --replicas n host1:port1 host2:port2 ...(启动过程中需
键入yes:
Can I set the above configuration? (type 'yes' to accept): yes
eg. 
redis-trib.rb create --replicas 1 172.31.108.52:17001 172.31.108.53:17002 172-
.31.108.54:17003 172.31.108.55:17004 172.31.108.53:17005 172.31.108.55:17006

redis各节点信息存于各配置节点root用户目录下redis目录中的cluster文件中，可通过
以下命令快捷获取。
cat ~/redis/cluster
