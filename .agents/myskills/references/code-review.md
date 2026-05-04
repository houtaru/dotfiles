# High-Impact Code Review & OSS Navigation

## Reading OSS Code
- **Top-Down**: Start with main loop/entry point to understand control flow.
- **Data-Driven**: Identify core data structures (structs/classes) first; logic follows data.
- **Trace Hot Paths**: Use `grep` or `ctags` to follow the path of a single request or operation.
- **Infrastructure First**: Understand the networking and storage abstraction layers before diving into business logic.

## Review Principles
- **Minimalist Changes**: Propose the smallest change that achieves the goal without breaking performance or safety.
- **Mechanical Sympathy**: Flag code that violates cache locality, causes branch misprediction, or unnecessary allocations.
- **Builtin Preference**: Suggest using compiler builtins or standard library features over adding new dependencies.
- **Correctness First**: Ensure thread safety and memory safety (especially in C/C++/Rust) before optimizing for speed.

## High Performance Review Checklist
1. Can this loop be unrolled or vectorized?
2. Is this branch predictable or can it be made branchless?
3. Are there unnecessary memory copies?
4. Can we use `mmap` or `sendfile` here?
5. Is this data structure cache-aligned?
