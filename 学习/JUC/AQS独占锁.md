# 独占锁



# 重要属性

```java
//头结点
private transient volatile Node head;

//尾结点
private transient volatile Node tail;

//同步状态 0-代表没锁 >1-上锁了
private volatile int state;

//当前持有锁的线程
private transient Thread exclusiveOwnerThread;
```

# Node节点

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

# 重要方法

## 加锁逻辑

### 加锁并入队

首先尝试快速获取锁,以cas的方式将state的值更新为1,只有当state的原值为0时更新才能成功,因为state在ReentrantLock的语境下等同于锁被线程重入的次数,这意味着只有当前锁未被任何线程持有时该动作才会返回成功。若获取锁成功,则将当前线程标记为持有锁的线程,然后整个加锁流程就结束了。若获取锁失败,则执行acquire方法

```java
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```

### 加锁

每个锁的实现不一样，有的是可重入锁，有的是不可重入的等，所以锁自己根据设计实现获取锁的功能

公平锁：直接加入队尾

非公平锁：先抢锁

```java
protected boolean tryAcquire(int arg) {
    throw new UnsupportedOperationException();
}
```

### 节点加入队列

和enq类似

```java
private Node addWaiter(Node mode) {
    Node node = new Node(Thread.currentThread(), mode);
    // Try the fast path of enq; backup to full enq on failure
    Node pred = tail;
    if (pred != null) {
        node.prev = pred;
        if (compareAndSetTail(pred, node)) {
            pred.next = node;
            return node;
        }
    }
    enq(node);
    return node;
}
```

### 入队逻辑

将新的节点通过CAS安全添加到阻塞队列末尾，等待唤醒使用

```java
private Node enq(final Node node) {
    for (;;) {
        Node t = tail;
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            node.prev = t;
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}
```

### 检查节点

判断之前的节点线程需不需要中断

```java
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
```

### 判断线程状态

其实这个方法的含义很简单,就是确保当前结点的前驱结点的状态为SIGNAL,SIGNAL意味着线程释放锁后会唤醒后面阻塞的线程。毕竟,只有确保能够被唤醒，当前线程才能放心的阻塞。

1、如果当前节点的前置节点的状态是 -1，则表示是激活状态，前置节点执行完成会唤醒下一个节点

2、如果ws > 0代表前置节点是等待超时或者取消等待的，不会唤醒下一个节点，所以需要找前置节点的前置节点，一直找到节点状态是 -1(可唤醒)的节点

3、如果节点ws不为-1，也不是>0，修改为-1

```java
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus;
    if (ws == Node.SIGNAL)   //对应 1
        return true;
    if (ws > 0) {   //对应 2
        do {
            node.prev = pred = pred.prev;
        } while (pred.waitStatus > 0);
        pred.next = node;
    } else { //对应 3
        compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false;
}
```

### 修改同步状态

通过CAS安全的修改state状态值

```java
protected final boolean compareAndSetState(int expect, int update) {
        // See below for intrinsics setup to support this
        return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
}
```

### 修改头结点

```java
private final boolean compareAndSetHead(Node update) {
    return unsafe.compareAndSwapObject(this, headOffset, null, update);
}
```

### 修改尾结点

```java
private final boolean compareAndSetTail(Node expect, Node update) {
    return unsafe.compareAndSwapObject(this, tailOffset, expect, update);
}
```

# 解锁逻辑

## 释放锁

```java
public final boolean release(int arg) {
    if (tryRelease(arg)) { //释放锁(state-1),若释放后锁可被其他线程获取(state=0),返回true
        //将需要激活的节点放到头结点head上(猜测)
        Node h = head;
        //当前队列不为空且头结点状态不为初始化状态(0)   
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);  //唤醒同步队列中被阻塞的线程
        return true;
    }
    return false;
}
```

### 尝试释放锁

需要每个锁自己定义释放功能

```java
protected boolean tryRelease(int arg) {
    throw new UnsupportedOperationException();
}
```

### 唤醒节点

**正常情况**：唤醒后继节点【头结点是一个空节点`compareAndSetHead(new Node())`】

**异常情况**：后继节点异常，取消等待。从队尾往前回溯，找到离头结点最近的正常节点，并唤醒其线程

```java
private void unparkSuccessor(Node node) {
    int ws = node.waitStatus;
    if (ws < 0)
        compareAndSetWaitStatus(node, ws, 0);
    Node s = node.next;
    //异常情况，从队尾开始回溯
    if (s == null || s.waitStatus > 0) {
        s = null;
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0)
                s = t;
    }
    if (s != null)
        LockSupport.unpark(s.thread);
}
```







