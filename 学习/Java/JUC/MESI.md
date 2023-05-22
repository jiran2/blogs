# 基本描述

| 状态                         | 独  占 | 描述                                                         | 监听任务                                                     |
| ---------------------------- | :----- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **M** 修改 (Modified)        | 是     | 该Cache line有效，数据被修改了，和内存中的数据不一致，数据只存在于本Cache中。 | 缓存行必须时刻监听所有试图读该缓存行相对主存的操作，这种操作必须在缓存将该缓存行写回主存并将状态变成S（共享）状态之前被延迟执行。 |
| **E** 独享、互斥 (Exclusive) | 是     | 该Cache line有效，数据和内存中的数据一致，数据只存在于本Cache中。 | 缓存行也必须监听其它缓存读主存中该缓存行的操作，一旦有这种操作，该缓存行需要变成S（共享）状态。 |
| **S** 共享 (Shared)          | 否     | 该Cache line有效，数据和内存中的数据一致，数据存在于很多Cache中。 | 缓存行也必须监听其它缓存使该缓存行无效或者独享该缓存行的请求，并将该缓存行变成无效（Invalid）。 |
| **I** 无效 (Invalid)         | 否     | 该Cache line无效。                                           | 无                                                           |

CPUA(E)->写回(S)

CPUB(读)->			->读取(S)



如果每一条修改都需要等待失效确认，性能很慢，引入 **Store Bufferes**

**Store Bufferes：**当有缓存修改，先写入Store Bufferes，等待所有失效消息被确认，再写入内存。

可能引发的问题：多线程并发情况下，别的CPU使用的还是旧的数据。

```java
value = 3；

void exeToCPUA(){
  value = 10;
  isFinsh = true;
}
void exeToCPUB(){
  if(isFinsh){
    //value一定等于10？！
    assert value == 10;
  }
}
```

试想一下开始执行时，CPU A保存着isFinsh在E(独享)状态，而value并没有保存在它的缓存中（例如：Invalid）。在这种情况下，value会比isFinsh更迟地抛弃存储缓存。完全有可能CPU B读取isFinsh的值为true，而value的值不等于10。



**存储缓存（Store Buffers）：**处理器把它想要写入到内存的值写到存储缓存，然后继续去处理其他事情。当所有失效确认（Invalidate Acknowledge）都接收到时，数据才会最终被提交到内存。

**失效队列（Invalidate Queue）：**

1. 对于所有的收到的Invalidate请求，Invalidate Acknowlege消息必须立刻发送
2. Invalidate并不真正执行，而是被放在一个特殊的队列中，在方便的时候才会去执行
3. 处理器不会发送任何消息给所处理的缓存条目，直到它处理Invalidate





**内存屏障（Memory Barrier）：**

1. 写屏障（Store Memory Barrier）：**store buffer**指令必须被执行完，保证之前修改的数据更新到内存中
2. 读屏障（Load Memory Barrier）：**失效队列**指令必须被执行完，如果内存数据已经被修改，本地缓存会失效，重新从内存中读取数据



CPU0读数据：

![读操作](https://img-blog.csdnimg.cn/20210410202450142.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NjIxNTYxNw==,size_16,color_FFFFFF,t_70#pic_center)

CPU0写数据：

![写操作](https://img-blog.csdnimg.cn/20210410203955242.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NjIxNTYxNw==,size_16,color_FFFFFF,t_70#pic_center)

参考文章：

1. https://blog.csdn.net/weixin_46215617/article/details/115433851
2. https://blog.csdn.net/weixin_46215617/article/details/115769890