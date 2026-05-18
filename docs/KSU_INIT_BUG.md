# KernelSU Init Bug on RMX3760 (Unisoc T612)

## Status: KSU-Only NOT Possible

The KernelSU Next v3.2.0 `ksud boot-patch` generates a boot/init_boot image with
a custom `init` binary that is supposed to load `kernelsu.ko` at early boot.

**This init binary fails silently on RMX3760.**

## Symptoms

- `kernelsu.ko` is embedded in ramdisk with correct vermagic
- Original Android `init` is preserved as `init.real`
- KSU init prints "Cannot load kernelsu.ko: init_module failed" (seen via strings)
- Device boots normally (KSU init falls through to exec init.real)
- Module NOT loaded (`lsmod | grep kernelsu` returns nothing)

## Root Cause

Unknown — the init binary (Rust ELF, statically linked, AArch64) calls
`init_module()` syscall which returns an error. Possible causes:

1. **Vermagic mismatch** (ruled out — fixed by removing `+` from LOCALVERSION)
2. **Module signature check** (CONFIG_MODULE_SIG=y, but CONFIG_MODULE_SIG_FORCE=n)
3. **CONFIG_MODULE_SIG_PROTECT** (Unisoc-specific, may block unsigned modules)
4. **KSU init binary bug** — path resolution for `../kernelsu.ko`, or incorrect syscall
5. **SELinux / lockdown** preventing module load during early init

## Workaround: Hybrid Magisk + KSU

| Layer | Component | Function |
|-------|-----------|----------|
| Boot | Magisk v27 init | Provides root via `su`, stable |
| Late boot | Magisk module `ksu_loader` | Runs `ksud late-load` via service.sh |
| Kernel | KernelSU Next LKM | Loaded by ksud, enables KSU app integration |
| Userspace | KernelSU Next app | Grant root to apps |

This hybrid approach is fully functional and reboot-safe.

## To Switch to KSU-Only in Future

The KSU init binary needs to be fixed to properly call `init_module()` with
flags, or use `finit_module()` with `MODULE_INIT_IGNORE_VERMAGIC` flag.
Alternatively, build a simple C init that:
1. Calls `init_module("kernelsu.ko", NULL, 0)`
2. On failure, tries `finit_module()` with ignored vermagic
3. Execs `init.real`
