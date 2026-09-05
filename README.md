# CarsonOS BLFS

CarsonOS BLFS is an experimental Linux distribution built from the Linux From Scratch (LFS) and Beyond Linux From Scratch (BLFS) methodology.

## Goals

- Build the base system from LFS
- Extend it with BLFS software
- Create a complete XFCE desktop
- Add networking, audio, graphics, fonts, and common utilities
- Produce a bootable CarsonOS ISO
- Eventually create a native package/build system
- Keep the build process open and reproducible

## Planned stack

| Component | Plan |
|---|---|
| Base | Linux From Scratch |
| Additional software | Beyond Linux From Scratch |
| Init | TBD |
| Desktop | XFCE initially |
| Display | Xorg initially; Wayland later |
| Audio | PipeWire |
| Networking | NetworkManager |
| Bootloader | GRUB |
| Architecture | x86_64 |
| Testing | QEMU / VirtualBox first |

## Build stages

1. Host validation
2. LFS toolchain
3. Temporary tools
4. Final LFS system
5. Linux kernel and bootloader
6. BLFS dependencies
7. Xorg
8. XFCE
9. Networking and audio
10. CarsonOS customization
11. ISO generation

## Repository layout

```text
CarsonOS-BLFS/
├── README.md
├── scripts/
├── packages/
├── config/
├── patches/
├── docs/
└── iso/
```

## Status

🚧 Early development — the repository is being turned into an automated LFS/BLFS build system.

## Safety / testing

The first builds should be tested in QEMU or VirtualBox before attempting installation on physical hardware.

## License

TBD.
