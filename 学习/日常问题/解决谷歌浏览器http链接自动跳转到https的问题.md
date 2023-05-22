有些网址http协议和https协议是两个服务，有时候需要访问http地址，但chrome会默认转成https请求地址。

比如：输入 [http://baidu.com](http://baidu.com/) 会自动跳转到 [https://baidu.com](https://baidu.com/)

这时候清理浏览器缓存之类的都是没有用的，需要进行如下操作

# 方法一：删除浏览缓存

## 1、打开缓存设置页面

在chrome浏览器地址输入：`chrome://net-internals/#hsts`

<img src="https://img-blog.csdnimg.cn/20190618224232686.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTIzNTk5OTU=,size_16,color_FFFFFF,t_70" alt="谷歌浏览器修改图片" style="zoom:50%;" />

## 2、删除缓存

在最下面的`Delete domain security policies`里输入想要删除的网址

注意是去掉http://前缀的网址，如：`www.baidu.com`

# 方法二：设置不安全访问为允许（推荐）

## 1、点击网址域名左边

## 2、点击网站设置

![img](https://img-blog.csdnimg.cn/20210531141703171.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhcHB5X2Jsb2NraGVhZA==,size_16,color_FFFFFF,t_70)

## 3、找到不安全内容选项，设置为允许

![img](https://img-blog.csdnimg.cn/20210531141718178.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhcHB5X2Jsb2NraGVhZA==,size_16,color_FFFFFF,t_70)