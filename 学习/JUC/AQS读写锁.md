属性

```java
static final int SHARED_SHIFT   = 16;
// 由于读锁用高位部分，所以读锁个数+1，其实是状态值+ 2^16
static final int SHARED_UNIT    = (1 << SHARED_SHIFT);
// 写锁的可重入的最大次数、读锁允许的最大数量
static final int MAX_COUNT      = (1 << SHARED_SHIFT) - 1;
// 写锁的掩码，用于状态的低16位有效值
static final int EXCLUSIVE_MASK = (1 << SHARED_SHIFT) - 1;

// 读锁计数，当前持有读锁的线程数
static int sharedCount(int c)    { return c >>> SHARED_SHIFT; }
// 写锁的计数，也就是它的重入次数
static int exclusiveCount(int c) { return c & EXCLUSIVE_MASK; }
```





```java
abstract static class Sync extends AbstractQueuedSynchronizer {
    /**
     * 每个线程特定的 read 持有计数。存放在ThreadLocal，不需要是线程安全的。
     */
    static final class HoldCounter {
        int count = 0;
        // 使用id而不是引用是为了避免保留垃圾。注意这是个常量。
        final long tid = Thread.currentThread().getId();
    }
    /**
     * 采用继承是为了重写 initialValue 方法，这样就不用进行这样的处理：
     * 如果ThreadLocal没有当前线程的计数，则new一个，再放进ThreadLocal里。
     * 可以直接调用 get。
     * */
    static final class ThreadLocalHoldCounter
        extends ThreadLocal<HoldCounter> {
        public HoldCounter initialValue() {
            return new HoldCounter();
        }
    }
    /**
     * 保存当前线程重入读锁的次数的容器。在读锁重入次数为 0 时移除。
     */
    private transient ThreadLocalHoldCounter readHolds;
    /**
     * 最近一个成功获取读锁的线程的计数。这省却了ThreadLocal查找，
     * 通常情况下，下一个释放线程是最后一个获取线程。这不是 volatile 的，
     * 因为它仅用于试探的，线程进行缓存也是可以的
     * （因为判断是否是当前线程是通过线程id来比较的）。
     */
    private transient HoldCounter cachedHoldCounter;
    /**
     * firstReader是这样一个特殊线程：它是最后一个把 共享计数 从 0 改为 1 的
     * （在锁空闲的时候），而且从那之后还没有释放读锁的。如果不存在则为null。
     * firstReaderHoldCount 是 firstReader 的重入计数。
     *
     * firstReader 不能导致保留垃圾，因此在 tryReleaseShared 里设置为null，
     * 除非线程异常终止，没有释放读锁。
     *
     * 作用是在跟踪无竞争的读锁计数时非常便宜。
     *
     * firstReader及其计数firstReaderHoldCount是不会放入 readHolds 的。
     */
    private transient Thread firstReader = null;
    private transient int firstReaderHoldCount;
    Sync() {
        readHolds = new ThreadLocalHoldCounter();
        setState(getState()); // 确保 readHolds 的内存可见性，利用 volatile 写的内存语义。
    }
}
```



# 读锁

## 加锁

```java
protected final int tryAcquireShared(int unused) {
    Thread current = Thread.currentThread();
    int c = getState();
    if (exclusiveCount(c) != 0 &&
        getExclusiveOwnerThread() != current)
        return -1; //有线程持有写锁，且该线程不是当前线程，获取锁失败。
    int r = sharedCount(c); //获取读锁的数量
    if (!readerShouldBlock() && //写锁空闲 且  公平策略决定 读线程应当被阻塞，除了重入获取，其他获取锁失败。
        r < MAX_COUNT && //读锁超过最大数量，也返回失败
        compareAndSetState(c, c + SHARED_UNIT)) {
        if (r == 0) {
            firstReader = current;
            firstReaderHoldCount = 1;
        } else if (firstReader == current) {
            firstReaderHoldCount++;
        } else {
            HoldCounter rh = cachedHoldCounter;
            if (rh == null || rh.tid != getThreadId(current))
                cachedHoldCounter = rh = readHolds.get();
            else if (rh.count == 0)
                readHolds.set(rh);
            rh.count++;
        }
        return 1;
    }
    return fullTryAcquireShared(current);
}
```





```java
final int fullTryAcquireShared(Thread current) {
    HoldCounter rh = null;
    for (; ; ) {
        int c = getState();
        if (exclusiveCount(c) != 0) {
            if (getExclusiveOwnerThread() != current)
                return -1;     //1.有线程持有写锁，且该线程不是当前线程，获取锁失败
            //2.有线程持有写锁，且该线程是当前线程，则应该放行让其重入获取锁，否则会造成死锁。
        } else if (readerShouldBlock()) {
            //3.写锁空闲  且  公平策略决定 读线程应当被阻塞
            // 下面的处理是说，如果是已获取读锁的线程重入读锁时，
            // 即使公平策略指示应当阻塞也不会阻塞。
            // 否则，这也会导致死锁的。
            if (firstReader == current) {
                // assert firstReaderHoldCount > 0;
            } else {
                if (rh == null) {
                    rh = cachedHoldCounter;
                    if (rh == null || rh.tid != current.getId()) {
                        rh = readHolds.get();
                        if (rh.count == 0)
                            readHolds.remove();
                    }
                }
                //4.需要阻塞且是非重入(还未获取读锁的)，获取失败。
                if (rh.count == 0)
                    return -1;
            }
        }
        //5.写锁空闲  且  公平策略决定线程可以获取读锁
        if (sharedCount(c) == MAX_COUNT)//6.读锁数量达到最多
            throw new Error("Maximum lock count exceeded");
        //7. 申请读锁成功，下面的处理跟tryAcquireShared是类似的。
        if (compareAndSetState(c, c + SHARED_UNIT)) {
            if (sharedCount(c) == 0) {
                firstReader = current;
                firstReaderHoldCount = 1;
            } else if (firstReader == current) {
                firstReaderHoldCount++;
            } else {
                if (rh == null)
                    rh = cachedHoldCounter;
                if (rh == null || rh.tid != current.getId())
                    rh = readHolds.get();
                else if (rh.count == 0)
                    readHolds.set(rh);
                rh.count++;
                cachedHoldCounter = rh; // cache for release
            }
            return 1;
        }
    }
}
```



## 解锁

```java
protected final boolean tryReleaseShared(int unused) {
    Thread current = Thread.currentThread();
    // 清理firstReader缓存 或 readHolds里的重入计数
    if (firstReader == current) {
        // assert firstReaderHoldCount > 0;
        if (firstReaderHoldCount == 1)
            firstReader = null;
        else
            firstReaderHoldCount--;
    } else {
        HoldCounter rh = cachedHoldCounter;
        if (rh == null || rh.tid != current.getId())
            rh = readHolds.get();
        int count = rh.count;
        if (count <= 1) {
            // 完全释放读锁
            readHolds.remove();
            if (count <= 0)
                throw unmatchedUnlockException();
        }
        --rh.count; // 主要用于重入退出
    }
    // 循环在CAS更新状态值，主要是把读锁数量减 1
    for (;;) {
        int c = getState();
        int nextc = c - SHARED_UNIT;
        if (compareAndSetState(c, nextc))
            // 释放读锁对其他读线程没有任何影响，
            // 但可以允许等待的写线程继续，如果读锁、写锁都空闲。
            return nextc == 0;
    }
}
```



# 写锁

## 加锁

```java
protected final boolean tryAcquire(int acquires) {
    Thread current = Thread.currentThread();
    int c = getState();
    int w = exclusiveCount(c);
    if (c != 0) {
        // 1.写锁为0，读锁不为0    或者写锁不为0，且当前线程不是已获取独占锁的线程，锁获取失败
        if (w == 0 || current != getExclusiveOwnerThread())
            return false;
        //2. 写锁数量已达到最大值，写锁获取失败
        if (w + exclusiveCount(acquires) > MAX_COUNT)
            throw new Error("Maximum lock count exceeded");
        // Reentrant acquire
        setState(c + acquires);
        return true;
    }
    //3.当前线程应该阻塞，或者设置同步状态state失败，获取锁失败。
    if (writerShouldBlock() ||
            !compareAndSetState(c, c + acquires))
        return false;
    setExclusiveOwnerThread(current);
    return true;
}
```



## 解锁

```java
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}

protected final boolean tryRelease(int releases) {
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    int nextc = getState() - releases;
    boolean free = exclusiveCount(nextc) == 0;
    if (free)
        setExclusiveOwnerThread(null);
    setState(nextc);
    return free;
}
```

