# 共享锁



## 释放共享变量

tryReleaseShared(arg)如果发现状态值为0，则doReleaseShared()执行线程

```java
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        doReleaseShared();
        return true;
    }
    return false;
}
```

## 启动主线程

唤醒下一个节点

`Node.PROPAGATE`还没看明白

```java
private void doReleaseShared() {
    for (;;) {
        Node h = head;
        if (h != null && h != tail) {
            int ws = h.waitStatus;
            if (ws == Node.SIGNAL) {
                if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                    continue;            // loop to recheck cases
                unparkSuccessor(h);
            }
            else if (ws == 0 &&
                     !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                continue;                // CAS失败就继续循环
        }
        if (h == head)                   // 只循环一次，如果节点头改变，则继续循环
            break;
    }
}
```

需要锁自己实现

```java
protected int tryAcquireShared(int arg) {
     throw new UnsupportedOperationException();
}
```

AQS通用释放

```java
private void doAcquireSharedInterruptibly(int arg)
    throws InterruptedException {
    final Node node = addWaiter(Node.SHARED); //该函数用于将当前线程相关的节点将入链表尾部
    boolean failed = true;
    try {
        for (;;) {  //将入无限for循环
            final Node p = node.predecessor();  //获得它的前节点
            if (p == head) {
                int r = tryAcquireShared(arg);
                if (r >= 0) {  //唯一的退出条件，也就是await()方法返回的条件很重要！！
                    setHeadAndPropagate(node, r);  //该方法很关键具体下面分析
                    p.next = null; // help GC
                    failed = false;
                    return;  //到这里返回
                }
            }
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())  // 先知道线程由该函数来阻塞的的
                throw new InterruptedException();
        }
    } finally {
        if (failed)  //如果失败或出现异常，失败 取消该节点，以便唤醒后续节点
            cancelAcquire(node);
    }
}
```



## 等待锁

```java
public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    if (tryAcquireShared(arg) < 0)
        doAcquireSharedInterruptibly(arg);
}
```





```java
private void setHeadAndPropagate(Node node, int propagate) {
    Node h = head; // Record old head for check below
    setHead(node);
    if (propagate > 0 || h == null || h.waitStatus < 0 ||
        (h = head) == null || h.waitStatus < 0) {
        Node s = node.next;
        if (s == null || s.isShared())
            doReleaseShared();
    }
}
```

