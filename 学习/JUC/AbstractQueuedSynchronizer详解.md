# AQS简介       

 队列同步器AbstractQueuedSynchronizer（以下简称同步器），是用来构建锁或者其他同步组件的基础框架，它使用了一个int成员变量表示同步状态，通过内置的FIFO队列来完成资源获取线程的排队工作，它是实现大部分同步需求的基础。 



同步器的主要使用方式是继承，子类通过继承同步器并实现它的抽象方法来管理同步状态，在抽象方法的实现过程中免不了要对同步状态进行更改，这时就需要使用同步器提供的三 个方法来进行操作

- java.util.concurrent.locks.AbstractQueuedSynchronizer.getState()
- java.util.concurrent.locks.AbstractQueuedSynchronizer.setState(int)
- java.util.concurrent.locks.AbstractQueuedSynchronizer.compareAndSetState(int, int)

子类推荐被定义为自定义同步组件的静态内部类，同步器自身没有实现任何同步接口，它仅仅是定义了若干同步状态获取和释放的方法来供自定义同步组件使用

同步器既可以支持独占式地获取同步状态，也可以支持共享式地获取同步状态

**独占锁**

1. ReentrantLock
2. ReentrantReadWriteLock.WriteLock

**共享锁**

1. CountDownLatch
2. Semaphore
3. CyclicBarrier
4. ReentrantReadWriteLock.ReadLock



同步器是实现锁（也可以是任意同步组件）的关键， 它简化了锁的实现方式，屏蔽了同步状态管理、线程的排队、等待与唤醒等底层操作。

# AQS作用

## 说明

## 锁实现

独占锁 state=1，共享锁 state>1

**独占锁**

1. ReentrantLock

**共享锁**

1. CountDownLatch
2. Semaphore
3. CyclicBarrier

**ReentrantReadWriteLock**

- 写锁：独占锁
- 读锁：共享锁

# AQS结构

<img src="C:\Users\ranji\AppData\Roaming\Typora\typora-user-images\image-20210514162431311.png" alt="image-20210514162431311" style="zoom:80%;" align="left"/>

# AQS属性

## 重要属性

```java
//头结点
private transient volatile Node head;

//尾结点
private transient volatile Node tail;

//同步状态 0-代表没锁 >=1-上锁了
private volatile int state;

//当前持有锁的线程
private transient Thread exclusiveOwnerThread;
```

## Node节点

每一个线程都会包装成Node

```java
volatile Node prev; //指向前一个结点的指针

volatile Node next; //指向后一个结点的指针

volatile Thread thread; //当前结点代表的线程

volatile int waitStatus; //等待状态  
0:初始化状态(仅仅ReentrantLock)
//CANCELLED，值为1，表示当前的线程被取消
//SIGNAL，值为-1，表示当前节点的后继节点包含的线程需要运行，也就是unpark
//CONDITION，值为-2，表示当前节点在等待condition，也就是在condition队列中
//PROPAGATE，值为-3，表示当前场景下后续的acquireShared能够得以执行
```



# AQS方法

## 加锁

共享锁



独占锁



## 解锁

共享锁



独占锁



参考资料：

1. https://ifeve.com/introduce-abstractqueuedsynchronizer/