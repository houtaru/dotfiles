# Chat Infrastructure Engineering

## Databases (SQL & NoSQL)
- **PostgreSQL**: Tuning for high-concurrency writes and large history tables. Use partitioned tables and BRIN/GIN indexes where appropriate.
- **NoSQL (Cassandra/ScyllaDB)**: Ideal for message persistence with wide-row patterns. Optimize compaction strategies and consistency levels (CL).
- **Redis**: Use for real-time presence, session management, and pub/sub. Optimize memory usage with ziplists and intsets.

## Message Queues
- **Throughput vs Latency**: Tuning Kafka or RabbitMQ for sub-second message delivery.
- **Backpressure**: Implementing flow control to prevent cascading failures.
- **Custom Pub/Sub**: Implementing high-performance Unix-native pub/sub using shared memory or domain sockets.

## Proxies & Load Balancing
- **HAProxy/Nginx**: Tuning for long-lived WebSocket/gRPC connections.
- **TLS Offloading**: Minimizing latency overhead for encrypted traffic.
- **Layer 4 vs Layer 7**: Choosing the right level for balancing based on protocol (TCP/HTTP).
