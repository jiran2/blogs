区别，独占锁 state=1，共享锁 state>1



独占锁：

1. ReentrantLock

共享锁：

1. CountDownLatch
2. Semaphore
3. CyclicBarrier



ReentrantReadWriteLock

- 写锁：独占锁
- 读锁：共享锁

