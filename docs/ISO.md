# CarsonOS BLFS ISO

The full build produces `output/carsonos-blfs-x86_64.iso` after the LFS target and kernel have been built.

The ISO is assembled with GRUB `grub-mkrescue`, which uses `xorriso` for ISO creation. The current first-generation image keeps the completed CarsonOS root tree under `/carsonos-root` so the image is easy to inspect while the live-root/initramfs layer is developed.

## Required host tools

- `grub-mkrescue`
- `xorriso`
- `file`
- `sha256sum`

## Output

- `carsonos-blfs-x86_64.iso`
- `carsonos-blfs-x86_64.iso.sha256`
- `build-manifest.txt`

The ISO workflow runs only after the LFS build stages succeed.
