# Low-Level Unix Systems Engineering

## I/O Multiplexing
- **Epoll (Linux)**: Efficiently handle millions of concurrent connections. Use edge-triggered (`EPOLLET`) for maximum performance but handle EAGAIN carefully.
- **IO_uring**: The modern Linux interface for asynchronous I/O. Use for high-throughput disk and network operations.
- **Kqueue (BSD/macOS)**: Equivalent high-performance multiplexer for non-Linux Unix systems.

## System Limits
- **File Descriptors**: Tuning `ulimit -n` and `/proc/sys/fs/file-max`.
- **TCP Stack**: Tuning `tcp_fin_timeout`, `tcp_keepalive`, and `tcp_max_syn_backlog` for high-concurrency chat systems.
- **Memory Limits**: Managing `mmap` limits and address space layout.

## Memory Management
- **Mmap**: Use for high-performance file I/O and shared memory.
- **Hugepages**: Reduce TLB misses for large memory-resident databases.
- **Copy-on-Write (CoW)**: Leverage `fork()` or `reflink` for efficient snapshots/backups.

## Process & Threading
- **CPU Affinity**: Bind critical threads to specific cores to minimize context switches.
- **Zero-Copy**: Use `sendfile()`, `splice()`, or `tee()` to move data between descriptors without user-space copying.
