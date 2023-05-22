# 集群总览

3主3从模式

| 服务器ip:port  | 节点名称           | 主/从        |
| -------------- | ------------------ | ------------ |
| 127.0.0.1:7001 | redis-cluster-7001 | 主           |
| 127.0.0.1:7002 | redis-cluster-7002 | 7001的从节点 |
| 127.0.0.1:7003 | redis-cluster-7003 | 主           |
| 127.0.0.1:7004 | redis-cluster-7004 | 7003的从节点 |
| 127.0.0.1:7005 | redis-cluster-7005 | 主           |
| 127.0.0.1:7006 | redis-cluster-7006 | 7005的从节点 |

# 安装实例

```shell
mkdir -p /usr/local/soft/redis
cd /usr/local/soft/redis
```

## 下载

```
wget https://download.redis.io/releases/redis-6.2.4.tar.gz
```

## 解压

```shell
tar -zxvf redis-6.2.4.tar.gz
mv redis-6.2.4 redis-cluster-7000
```

## 安装

```shell
cd redis-cluster-7000
yum install gcc
make MALLOC=libc
cd src
make install
```

## 配置

位置

```
vi /usr/local/soft/redis/redis-cluster-7000/redis.conf
```

修改配置

```shell
# redis.conf
# Redis端口号 每个Redis实例修改端口号就行
port 7000
# Redis服务器集群模式启动
cluster-enabled yes
# 集群节点信息
cluster-config-file "node-6379.conf"
# Redis日志
logfile "redis.log"
# dbfilename "dump-6379.rdb"
# 后台启动Redis
daemonize yes
```

复制集群

```shell
cp -r /usr/local/soft/redis/redis-cluster-7000 /usr/local/soft/redis/redis-cluster-7001
cp -r /usr/local/soft/redis/redis-cluster-7000 /usr/local/soft/redis/redis-cluster-7002
cp -r /usr/local/soft/redis/redis-cluster-7000 /usr/local/soft/redis/redis-cluster-7003
cp -r /usr/local/soft/redis/redis-cluster-7000 /usr/local/soft/redis/redis-cluster-7004
cp -r /usr/local/soft/redis/redis-cluster-7000 /usr/local/soft/redis/redis-cluster-7005
cp -r /usr/local/soft/redis/redis-cluster-7000 /usr/local/soft/redis/redis-cluster-7006
```

注意：复制集群后将集群中配置文件的端口号修改为集群节点的端口号

```shell
# port 7001
vi /usr/local/soft/redis/redis-cluster-7001/redis.conf
# port 7002
vi /usr/local/soft/redis/redis-cluster-7002/redis.conf
# port 7003
vi /usr/local/soft/redis/redis-cluster-7003/redis.conf
# port 7004
vi /usr/local/soft/redis/redis-cluster-7004/redis.conf
# port 7005
vi /usr/local/soft/redis/redis-cluster-7005/redis.conf
# port 7006
vi /usr/local/soft/redis/redis-cluster-7006/redis.conf
```



# 启动集群

```shell
# 启动7001节点
cd /usr/local/soft/redis/redis-cluster-7001/src
./redis-sever ../redis.conf
# 启动7002节点
cd /usr/local/soft/redis/redis-cluster-7002/src
./redis-sever ../redis.conf
# 启动7003节点
cd /usr/local/soft/redis/redis-cluster-7003/src
./redis-sever ../redis.conf
# 启动7004节点
cd /usr/local/soft/redis/redis-cluster-7004/src
./redis-sever ../redis.conf
# 启动7005节点
cd /usr/local/soft/redis/redis-cluster-7005/src
./redis-sever ../redis.conf
# 启动7006节点
cd /usr/local/soft/redis/redis-cluster-7006/src
./redis-sever ../redis.conf
```

查看集群信息



```
redis-cli -p 7000 cluster meet 10.135.119.101 7002
```





设置主从

```
redis-cli  (从)-p 6479 cluster replicate (主)87b7
```

执行

```shell
redis-cli  -p 7002 cluster replicate 87b7dfacde34b3cf57d5f46ab44fd6fffb2e4f52
redis-cli  -p 7004 cluster replicate c47598b25205cc88abe2e5094d5bfd9ea202335f
redis-cli  -p 7006 cluster replicate 51081a64ddb3ccf5432c435a8cf20d45ab795dd8
```



分配嘈节点

```shell
redis-cli  -p 7001 cluster addslots {0..5000}
redis-cli  -p 7003 cluster addslots {5001..10000}
redis-cli  -p 7005 cluster addslots {10001..16383}
```

删除槽节点

```she
./redis-cli -p 7002 cluster delslots {0..16383}
```



自动根据给定的节点列表 创建以主节点+从节点对组

```shell
redis-cli --cluster create  127.0.0.1:6379 127.0.0.1:6479  127.0.0.1:6380 127.0.0.1:6480  127.0.0.1:6381 127.0.0.1:6481  --cluster-replicas 1
--cluster-replicas 1
```



报错提示

```shell
(error) MOVED 5798 127.0.0.1:7002
```

客户端需要使用集群模式开始

```sh
redis-cli -c -p 7000
```



故障转移

主节点下线，子节点会提升为主节点，然后原来的主节点再上线会变为子节点



集群伸缩

```sh
[root@izj6chpxushj67ruqdfsskz src]# ./redis-cli --cluster help
Cluster Manager Commands:
  create         host1:port1 ... hostN:portN
                 --cluster-replicas <arg>
  check          host:port
                 --cluster-search-multiple-owners
  info           host:port
  fix            host:port
                 --cluster-search-multiple-owners
                 --cluster-fix-with-unreachable-masters
  reshard        host:port
                 --cluster-from <arg>
                 --cluster-to <arg>
                 --cluster-slots <arg>
                 --cluster-yes
                 --cluster-timeout <arg>
                 --cluster-pipeline <arg>
                 --cluster-replace
  rebalance      host:port
                 --cluster-weight <node1=w1...nodeN=wN>
                 --cluster-use-empty-masters
                 --cluster-timeout <arg>
                 --cluster-simulate
                 --cluster-pipeline <arg>
                 --cluster-threshold <arg>
                 --cluster-replace
  add-node       new_host:new_port existing_host:existing_port
                 --cluster-slave
                 --cluster-master-id <arg>
  del-node       host:port node_id
  call           host:port command arg arg .. arg
                 --cluster-only-masters
                 --cluster-only-replicas
  set-timeout    host:port milliseconds
  import         host:port
                 --cluster-from <arg>
                 --cluster-from-user <arg>
                 --cluster-from-pass <arg>
                 --cluster-from-askpass
                 --cluster-copy
                 --cluster-replace
  backup         host:port backup_directory
  help
```





删除节点

先将槽节点分配出去

```shell
redis-cli --cluster reshard 
```

删除集群节点

```shell
redis-cli --cluster del-node
```





添加节点

```shell
redis-cli --cluster add-node
```



