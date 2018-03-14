#!/bin/bash

>${PWD}/redis/cluster
seven=17000
sbin=/usr/local/sbin
bin=/usr/local/bin
sbin2=/usr/sbin
bin2=/usr/bin
bin3=/root/bin
way_redis=/home/data/redis
cluster=/home/data/redis/cluster

read -p "请输入需要布置的redis集群服务器数量(>=6)：" redis_num

while [ "$redis_num" -lt "6" ]
do
	read -p "请输入需要布置的redis集群服务器数量(>=6)：" redis_num
done

for i in `seq $redis_num`
do
read -p "请输入第$i台redis服务器ip：" redis_ip
redis_[$i]=$redis_ip
let port_[$i]=seven+i
echo -n "$redis_ip:${port_[$i]} " >> ${PWD}/redis/cluster
done

for i in `seq $redis_num`
do
scp -r ${PWD}/redis ${redis_[$i]}:$HOME
done


for i in `seq $redis_num`
do
pdsh -w ssh:${redis_[$i]} "systemctl stop firewalld.service;
systemctl disable firewalld.service;
sed -i 's/enforcing/disabled/' /etc/selinux/config;
sed -i 's/permissive/disabled/' /etc/selinux/config;
yes|cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
mkdir -p /home/data/redis/cluster/${port_[$i]}/{conf,data,log,pid}"
done

for i in `seq $redis_num`
do
pdsh -w ssh:${redis_[$i]} "cd $HOME/redis;
rpm -ivh jemalloc-5.0.1-1.fc28.x86_64.rpm;
rpm -ivh redis-4.0.6-1.fc28.x86_64.rpm;
cd $HOME/redis/ruby;
yum -y --disablerepo=\* localinstall *.rpm"
done



for i in `seq $redis_num`
do
pdsh -w ssh:${redis_[$i]} "sed -i "/$way_redis/d" /etc/profile;
sed -i '/ruby23/d' /etc/profile;
echo "export PATH=$sbin:$bin:$sbin2:$bin2:$bin3:$way_redis" >> /etc/profile;
source /etc/profile;

echo -n 'export PATH=/opt/rh/rh-ruby23/root/usr/local/bin:' >> /etc/profile;
echo '/opt/rh/rh-ruby23/root/usr/bin${PATH:+:${PATH}}' >> /etc/profile;
echo -n 'export LD_LIBRARY_PATH=/opt/rh/rh-ruby23/root/' >> /etc/profile;
echo -n 'usr/local/lib64:/opt/rh/rh-ruby23/root/usr/lib64' >> /etc/profile;
echo '${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> /etc/profile;
source /etc/profile;

cd $HOME/redis;
gem install -l redis-4.0.1.gem"
done

for i in `seq $redis_num`
do
pdsh -w ssh:${redis_[$i]} "yes|cp $HOME/redis/redis-trib.rb $way_redis;
yes|cp $HOME/redis/redis-trib.rb /usr/bin/;
chmod +x $way_redis/redis-trib.rb;
chmod +x /usr/bin/redis-trib.rb"
done

for i in `seq $redis_num`
do
pdsh -w ssh:${redis_[$i]} "yes|cp /etc/redis.conf $cluster/${port_[$i]}/conf/;
cat $HOME/redis/redis.conf > $cluster/${port_[$i]}/conf/redis.conf;
sed -i "s/redis_port/${port_[$i]}/" $cluster/${port_[$i]}/conf/redis.conf;
sed -i "s/redis_bind/${redis_[$i]}/" $cluster/${port_[$i]}/conf/redis.conf"
done


for i in `seq $redis_num`
do
pdsh -w ssh:${redis_[$i]} "
echo 'systemctl start redis' >> $HOME/redis/redisstart.sh;
echo "redis-server /home/data/redis/cluster/${port_[$i]}/conf/redis.conf" \
>> $HOME/redis/redisstart.sh;
yes|cp $HOME/redis/redisstart.sh /etc/rc.d/init.d/;
cd /etc/rc.d/init.d/;
chmod +x redisstart.sh;
chkconfig --add redisstart.sh;
chkconfig redisstart.sh on;
systemctl enable redis;
systemctl start redis;
redis-server /home/data/redis/cluster/${port_[$i]}/conf/redis.conf"
done

cluster_list=`cat ${PWD}/redis/cluster`
pdsh -w ssh:${redis_[$redis_num]} "source /etc/profile;
echo yes |redis-trib.rb create --replicas 1 $cluster_list"
