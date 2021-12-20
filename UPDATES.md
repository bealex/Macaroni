# New Features and Migrations

This document contains only short feature and update descriptions. Please refer to [README.md](README.md) for details.

## Version 3

In this version main updates are:
 - change in `Container.policy`. It is more configurable now, because it is not an enum, but a protocol `ContainerFindable`.
   Old behavior is recreated in `.singleton(...)`, `.enclosingType`. Custom policy removed, please
   create your own implementation for that.
 - `@Injected` has two options now (`captureContainerLookupOnInit` parameter):
   - old one, when container is being searched lazily, on first access. Container.policy is being accessed for that
     and container is being looked up by it.
   - new one, when container lookup policy is being captured when injected property is created. Container is still
     being looked up lazily on first property access, but container lookup is being captured strongly during 
     initialization.
