# 配置Linux机器

## 配置系统环境

### 关闭防火墙

```shell
systemctl stop firewalld.service #停止firewall
systemctl disable firewalld.service #禁止firewall开机启动
```

### sysctl.conf

vi /etc/sysctl.conf

```shell
# 禁用内存与硬盘交换
vm.swappiness=1
# 设置虚拟内存大小
vm.max_map_count=262144
```

### limits.conf

vi /etc/security/limits.conf

```
# 进程线程数
* soft nproc 131072
* hard nproc 131072
# 文件句柄数
* soft nofile 131072
* hard nofile 131072
# 内存锁定交换
* soft memlock unlimited
* hard memlock unlimited
```

## 创建ES专用账号

Elasticsearch不能用root账号启动，会报错

Elasticsearch和kibana机器都要执行

```shell
# 创建 ES 账号，如 elastic
useradd elastic
# 授权 ES 程序目录 elastic 账号权限
# 假设 ES 程序目录、数据目录、日志目录都 在/elk 目录下
mkdir -p /usr/local/soft/elk
chown -R elastic:elastic /usr/local/soft/elk
```

## 下载软件

- JDK
  所有机器需要下载
  
  ```shell
  # 下载JDK
  mkdir /usr/local/soft/jdk
  cd /usr/local/soft/jdk
  # JDK下载地址
  wget https://download.oracle.com/java/17/archive/jdk-17.0.4.1_linux-x64_bin.tar.gz
  # 解压下载包
  tar -zxvf jdk-17_linux-x64_bin.tar.gz
  ```
  
- Elasticsearch
  部署Elasticsearch机器下载
  
  ```shell
  # 进入elk目录
  cd /usr/local/soft/elk
  # 下载Elasticsearch 如果速度很慢，可以使用迅雷下载上传到服务器
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.6-linux-x86_64.tar.gz
  ```
  
- Kibana
  部署Kibana机器下载
  
  ```shell
  # 进入elk目录
  cd /usr/local/soft/elk
  # 下载Kibana 如果速度很慢，可以使用迅雷下载上传到服务器
  wget https://artifacts.elastic.co/downloads/kibana/kibana-7.17.6-linux-x86_64.tar.gz
  ```

## 配置JDK17+

**打开配置文件**

vi /etc/profile

**配置路径**

```shell
# ES 最新版本自带 jdk 版本，默认可以不需要配置，建议配置，便于安装其它 java 程序辅助
export JAVA_HOME=/usr/local/soft/jdk/jdk-17.0.4.1  # JAVA_HOME路径地址每个人可能不一样，看下自己的安装路径
export JRE_HOME=${JAVA_HOME}/jre  
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib  
export PATH=${JAVA_HOME}/bin:$PATH
```

**检查配置是否成功**

```shell
#刷新配置
source /etc/profile
#检查是否正常
java -version
```

# 配置单点

解压Elasticsearch

```shell
# 解压下载包
cd /usr/local/soft/elk
tar -zxvf elasticsearch-7.17.0-linux-x86_64.tar.gz
mv elasticsearch-7.17.0 elasticsearch-single
```

解压Kibana

```shell
# 解压下载包
cd /usr/local/soft/elk
tar -zxvf kibana-7.17.0-linux-x86_64.tar.gz
mv kibana-7.17.0-linux-x86_64 kibana-single
```

## Elasticsearch配置

### 配置文件

- elasticsearch.yml
  vi /usr/local/soft/elk/elasticsearch-single/config/elasticsearch.yml
  **注意：每个冒号后面需要有空格**
  
  ```shell
  # 集群名称，默认可以不修改，此处 es-single-9200
  cluster.name: es-single
  # 节点名称，必须修改 ，默认修改为当前机器名称，若是多实例则需要区分
  node.name: es-single-9200
  # IP 地址，默认是 local，仅限本机访问，外网不可访问，设置 0.0.0.0 通用做法
  # network.host:192.168.2.100
  network.host: 0.0.0.0
  # 访问端口，默认 9200，9300，建议明确指定
  http.port: 9200
  transport.port: 9300
  # 数据目录与日志目录，默认在当前运行程序下，生产环境需要指定
  # path.data: /path/to/data
  # path.logs: /path/to/logs
  # 内存交换锁定，此处需要操作系统设置才生效
  bootstrap.memory_lock: true
  # 防止批量删除索引
  action.destructive_requires_name: true
  # 设置处理器数量，默认无需设置，单机器多实例需要设置
  node.processors: 2
  #默认单节点集群模式
  discovery.type: single-node
  #节点发现
  discovery.seed_hosts: ["192.168.0.190:9300"]
  #集群初始化节点
  #cluster.initial_master_nodes: ["192.168.2.100:9300"]
  #部分电脑CPU不支持SSE4.2+，启动会报错，设置禁止机器学习功能
  #xpack.ml.enable: false
  ```
  
- jvm.options
  vi /usr/local/soft/elk/elasticsearch-single/config/jvm.options
  
  只需要修改下内存大小就行了
  
  ```
  # 内存堆栈大小，不能超过 1/2 系统内存，多实例要谨慎（自己根据系统修改）
  -Xms1g
  -Xmx1g
  # 垃圾回收器 CMS 与 G1，当前 CMS 依然最好
  # 根据当前Java版本设置
  8-13:-XX:+UseConcMarkSweepGC
  14-:-XX:+UseG1GC
  -XX:+UseG1GC
  # GC.log 目录，便于排查 gc 问题，生产需要修改路径指向，下面是默认地址
  8:-Xloggc:logs/gc.log
  ```

### 启动方式

```shell
# 授权
chown -R elastic:elastic /usr/local/soft/elk/*
# 启动需要用创建的用户，不能用root用户
su elastic

# 当前窗口启动，窗口关闭，ES 进程也关闭
/usr/local/soft/elk/elasticsearch-single/bin/elasticsearch
# 后台进程启动(推荐使用)
/usr/local/soft/elk/elasticsearch-single/bin/elasticsearch -d

# 检查启动成功
http://192.168.0.190:9200/_cat/health
```

## Kibana配置

### 配置文件

- kibana.yml
  vi /usr/local/soft/elk/kibana-single/config/kibana.yml
  
  ```shell
  # 访问端口，默认无需修改
  server.port: 5600
  # 访问地址 IP，默认本地
  server.host: "192.168.0.190" 
  # ES 服务指向，集群下配置多个
  elasticsearch.hosts: ["http://192.168.0.190:9200"]
  # Kibana 元数据存储索引名字，默认.kibana 无需修改
  kibana.index: ".kibana_single"
  ```

### 启动方式

```shell
# 设置账号权限
chown -R elastic:elastic /usr/local/soft/elk/*
# 启动需要用创建的用户，不能用root用户
# su elastic

cd /usr/local/soft/elk/kibana-single/bin/
# 当前窗口内启动
./kibana
# 后台进程启动(推荐使用)
nohup ./kibana &
# 查看日志
tail -fn 200 /usr/local/soft/elk/kibana-single/bin/nohup.out
# kibana地址
http://192.168.0.190:5600
```



# 配置集群

**Elasticsearch 机器**

集群模式必须至少 2 个实例以上，一般建议 3 个节点以上，保障其中一个节点失效，集群仍然可以服务。

集群模式与单实例模式大部分配置上一样的，仅需修改集群通信差异部分。

| 服务器ip:port      | 节点名称           | JVM        |
| ------------------ | ------------------ | ---------- |
| 192.168.0.201:9200 | 192.168.0.201-9200 | jdk-17.0.1 |
| 192.168.0.202:9200 | 192.168.0.202-9200 | jdk-17.0.1 |

**Kibana机器**

| 服务器ip:port      | 节点名称           | JVM        |
| ------------------ | ------------------ | ---------- |
| 192.168.0.200:9200 | 192.168.0.200-5601 | jdk-17.0.1 |

**Elasticsearch机器执行**

```shell
# 解压下载包
cd /usr/local/soft/elk

tar -zxvf elasticsearch-7.17.6-linux-x86_64.tar.gz
cp -r elasticsearch-7.17.6 elasticsearch-cluster-9200
cp -r elasticsearch-7.17.6 elasticsearch-cluster-9201
```

**Kibana机器执行**

按照**下载软件**将Kibana下载到本地

```shell
# 解压下载包
cd /usr/local/soft/elk
tar -zxvf kibana-7.17.6-linux-x86_64.tar.gz
mv kibana-7.17.6-linux-x86_64 kibana-cluster
```

## Elasticsearch配置

### 配置文件

- elasticsearch.yml
  vi /usr/local/soft/elk/elasticsearch-cluster-9200/config/elasticsearch.yml
  **节点1**
  
  ```shell
  # 集群名称，默认可以不修改，此处 es-cluster
  cluster.name: es-cluster
  # 节点名称(每个节点的名称不一样)
  node.name: ${HOSTNAME}-9200
  # IP 地址，默认是 local，仅限本机访问，外网不可访问，设置 0.0.0.0 通用做法，集群环境需要每个节点啊绑定一个当前IP地址
  network.host: 192.168.0.201
  # network.host: 0.0.0.0
  # 网络端口 
  # 依次每台机器设置为 
  http.port: 9200
  transport.port: 9300
  # 集群节点之间指向
  discovery.seed_hosts: ["192.168.0.201:9300", "192.168.0.202:9300"]
  cluster.initial_master_nodes: ["192.168.0.201:9300","192.168.0.202:9300"]
  
  xpack.security.enabled: true
  ```
  
  **节点2**
  
  ```shell
  # 集群名称，默认可以不修改，此处 es-cluster
  cluster.name: es-cluster
  # 节点名称(每个节点的名称不一样)
  node.name: ${HOSTNAME}-9200
  # IP 地址，默认是 local，仅限本机访问，外网不可访问，设置 0.0.0.0 通用做法，集群环境需要每个节点啊绑定一个当前IP地址
  network.host: 192.168.0.202
  # network.host: 0.0.0.0
  # 网络端口 
  # 依次每台机器设置为 
  http.port: 9200
  transport.port: 9300
  # 集群节点之间指向
  discovery.seed_hosts: ["192.168.0.201:9300", "192.168.0.202:9300"]
  cluster.initial_master_nodes: ["192.168.0.201:9300","192.168.0.202:9300"]
  
  xpack.security.enabled: true
  ```
  
- 注意事项
  1、每个节点的名称不一样
  2、集群环境需要每个节点啊绑定一个IP地址https://blog.csdn.net/weixin_33670713/article/details/91550116

### 启动方式

每个Elasticsearch机器都执行

```shell
# 授权
chown -R elastic:elastic /usr/local/soft/elk/*

# 启动需要用创建的用户，不能用root用户
su elastic

# 当前窗口启动，窗口关闭，ES 进程也关闭
/usr/local/soft/elk/elasticsearch-cluster-9200/bin/elasticsearch
# 后台进程启动(推荐使用)
/usr/local/soft/elk/elasticsearch-cluster-9200/bin/elasticsearch -d

# 查看节点启动成功没
http://192.168.0.201:9200/_cat/health
```

## Kibana配置

### 配置文件

- kibana.yml
  vi /usr/local/soft/elk/kibana-cluster/config/kibana.yml
  
  ```shell
  # 访问端口
  server.port: 5601
  # 访问地址 IP，默认本地
  # server.host: "192.168.222.100" 
  server.host: "0.0.0.0" 
  
  # ES 服务指向，集群下配置多个
  elasticsearch.hosts: ["http://192.168.0.201:9200","http://192.168.0.202:9200"]
  # Kibana 元数据存储索引名字，默认.kibana 无需修改
  kibana.index: ".kibana_cluster"
  ```

### 启动方式

```shell
chown -R elastic:elastic /usr/local/soft/elk/*

# 启动需要用创建的用户，不能用root用户
su elastic

# 当前窗口内启动
cd /usr/local/soft/elk/kibana-cluster/bin
./kibana

# 后台进程启动(推荐使用)
nohup ./kibana &

# 查看日志
tail -fn 200 nohup.out

# 界面地址
http://192.168.0.200:5601
```

### 效果展示

#### 图片展示

可以看到三个节点集群启动成功

<img src="https://gitee.com/kitten8/typora-img/raw/master/imgs/image-20201117232119687.png" alt="image-20201117232119687" style="zoom:50%;" align='left'/>

#### 命令使用

使用elasticsearch命令查看集群状态

http://192.168.0.201:9200/_cat/

以下命令都可以使用

<img src="https://gitee.com/kitten8/typora-img/raw/master/imgs/image-20220825005600033.png" alt="image-20220825005600033" style="zoom:50%;" align='left'/>

举例：http://192.168.0.201:9200/_cat/nodes

查看当前集群得所有节点信息

<img src="https://gitee.com/kitten8/typora-img/raw/master/imgs/image-20220825005641888.png" alt="image-20220825005641888" style="zoom:100%;" align='left'/>

# 插件配置

## Elasticsearch Head

1. 下载插件：chrome应用市场搜`elasticsearch head`

   <img src="https://gitee.com/kitten8/typora-img/raw/master/imgs/image-20210305232732140.png" alt="image-20210305232732140" style="zoom:50%;" align='left'/>

2. 在chrome浏览器输入
   
   ```
   chrome-extension://ffmkiejjmecolpfloofpjologoblkegm/elasticsearch-head/index.html
   ```
   
3. 在`elasticsearch head`中输入集群某个节点地址
   <img src="https://gitee.com/kitten8/typora-img/raw/master/imgs/image-20210305233016620.png" alt="image-20210305233016620" style="zoom:50%;" />

## Elasticvue

1. 地址：https://chrome.google.com/webstore/detail/elasticvue/hkedbapjpblbodpgbajblpnlpenaebaa?hl=zh-CN
2. 效果展示（很美）
   <img src="https://gitee.com/kitten8/typora-img/raw/master/imgs/image-20210306132313965.png" alt="image-20210306132313965" style="zoom:50%;" />

# 注意事项

1. Ghelper插件：http://googlehelper.net/

2. 集群重启可能有日志文件elastic用户没有权限，需要重新执行给文件权限

   ```
   chown -R elastic:elastic /usr/local/soft/elk/*
   ```

   

