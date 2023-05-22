# JDK安装

下载JDK

```bash
wget <https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz>
```

检测系统是否自带openjdk

```bash
rpm -qa | grep java 
rpm -qa | grep jdk
```

批量卸载所有名字包含jdk的已安装程序

```bash
rpm -qa | grep jdk | xargs rpm -e --nodeps
```

批量卸载所有名字包含java的已安装程序

```bash
rpm -qa | grep java | xargs rpm -e --nodeps
```

打开profile文件

```bash
vim /etc/profile
```

在profile文件配置如下内容

```bash
export JAVA_HOME=/usr/local/soft/jdk1.8.0_231
export JRE_HOME=${JAVA_HOME}/jre  
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib  
export PATH=${JAVA_HOME}/bin:$PATH
```

重启配置文件

```bash
source /etc/profile
```

检查安装成功否