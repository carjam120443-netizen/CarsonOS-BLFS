# Building CarsonOS BLFS

CarsonOS BLFS is currently in the bootstrap stage. The build system will be developed in stages rather than attempting to build the entire distribution in one script.

## Development host

Use a supported Linux build host with enough free disk space, RAM, CPU time, and network access for compiling a large source tree.

For development, use a virtual machine first. QEMU and VirtualBox are the initial test targets.

## Build model

```text
Host Linux
   │
   ├── Host validation
   │
   ├── LFS sources
   │      └── temporary toolchain
   │
   ├── LFS base system
   │
   ├── Linux kernel + bootloader
   │
   ├── BLFS packages
   │      ├── libraries
   │      ├── Xorg
   │      ├── XFCE
   │      ├── NetworkManager
   │      └── PipeWire
   │
   └── CarsonOS image
```

## Current state

The repository contains project documentation and the initial directory plan. Build scripts will be added after the LFS/BLFS versions and package sources are pinned.

## Principle

Do not hard-code moving package versions into random scripts. Package versions, checksums, download locations, and build instructions should be tracked in a controlled manifest so future builds can be reproduced.
