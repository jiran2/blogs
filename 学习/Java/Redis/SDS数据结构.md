int编码、embstr编码、raw编码

![img](https://static001.geekbang.org/resource/image/ce/e3/ce83d1346c9642fdbbf5ffbe701bfbe3.jpg)





Redis 会使用一个全局哈希表保存所有键值对，哈希表的每一项是一个 dictEntry 的结构体，用来指向一个键值对。dictEntry 结构中有三个 8 字节的指针，分别指向 key、value 以及下一个 dictEntry，三个指针共 24 字节，如下图所示：

![img](https://static001.geekbang.org/resource/image/b6/e7/b6cbc5161388fdf4c9b49f3802ef53e7.jpg)



jemalloc 在分配内存时，会根据我们申请的字节数 N，找一个比 N 大，但是最接近 N 的 2 的幂次数作为分配的空间，这样可以减少频繁分配的次数。



buf两种分配策略（内存不足才会重新分配，如果未使用空间满足当前需求，就不会重新分配空间）

1. 长度小于1M，多分配一倍的空间
2. 长度大于1M，多分配1M的空间









Redis 会使用一个全局哈希表保存所有键值对，哈希表的每一项是一个 dictEntry 的结构体，用来指向一个键值对。dictEntry 结构中有三个 8 字节的指针，分别指向 key、value 以及下一个 dictEntry，三个指针共 24 字节，如下图所示：

![img](https://static001.geekbang.org/resource/image/b6/e7/b6cbc5161388fdf4c9b49f3802ef53e7.jpg)



https://blog.csdn.net/weixin_36180385/article/details/112179063