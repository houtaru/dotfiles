# High-Performance Code Optimization

## Core Philosophy
Prioritize performance through mechanical sympathy, minimizing abstraction overhead, and leveraging hardware capabilities.

## Optimization Techniques

### SIMD (Single Instruction, Multiple Data)
- **Vectorization**: Use CPU-specific intrinsics (AVX2, AVX-512, NEON) for parallel data processing.
- **Alignment**: Ensure data structures are properly aligned to cache line boundaries for optimal SIMD loads/stores.

### Loop Unrolling
- **Manual Unrolling**: Reduce loop overhead by processing multiple elements per iteration.
- **Duff's Device**: A classic technique for manual unrolling in C.
- **Compiler Hints**: Use `#pragma unroll` or equivalent when appropriate, but prefer explicit patterns in performance-critical paths.

### Branch Reduction
- **Branchless Logic**: Use bitwise operations, conditional moves (CMOV), and lookup tables to avoid branches.
- **Likely/Unlikely Hints**: Use `__builtin_expect` (in C/C++) to guide compiler branch prediction.
- **Sorting Data**: Process sorted data to make branches highly predictable.

### Memory Hierarchy
- **Cache Locality**: Design data structures for temporal and spatial locality.
- **Avoid False Sharing**: Ensure threads don't write to different variables on the same cache line.
- **Prefetching**: Use `__builtin_prefetch` to bring data into cache before use.

## Dependency Management
- **Builtins Over Libraries**: Favor compiler builtins (e.g., `__builtin_popcount`, `__builtin_clz`) and standard library primitives over external dependencies.
- **Minimalism**: Every dependency is a potential bottleneck and security risk. Implement high-performance primitives from scratch if they are core to the hot path.
