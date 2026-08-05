.\spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl .\fdl1-dl.bin 0x65000800 fdl .\fdl2-dl.bin 0x9efffe00 exec

w misc "D:\realme-c53-recovery\02_bahan\porting_full_slotAB\misc.img"
w metadata "D:\realme-c53-rom-backup\metadata.img"
reset

====================================================================================

read_part fbootlogo 0 8388608 "D:\realme-c53-recovery\02_bahan\readback_verifikasi\check_fbootlogo.bin"
read_part ocdt_a 0 8388608 "D:\realme-c53-recovery\02_bahan\readback_verifikasi\check_ocdt_a.bin"
read_part miscdata 0 1048576 "D:\realme-c53-recovery\02_bahan\readback_verifikasi\check_miscdata.bin"

=================================
Tes murah & reversibel: matikan AVB dulu — flash vbmeta_disabled.img ke vbmeta_a, lalu reset:
w vbmeta_a "D:\porting-custom-rom\vbmeta_disabled.img"
reset

w vbmeta_a "D:\porting-custom-rom\vbmeta_disabled.img"
reset
===================================================
FDL2 >w vbmeta_a "D:\realme-c53-recovery\02_bahan\backup_utama\vbmeta_a.img"
file size : 0x100000
[========================================] 100.0%
Write Part Done: vbmeta_a, target: 0x100000, written: 0x100000
FDL2 > ini terakhir
============================================================================
Firmware referensi (yang sudah verified MATCH dengan device) tersebar di beberapa folder:
Backup original hp ini (paling bisa dipercaya):

- D:\realme-c53-rom-backup\ — backup paling awal & lengkap: super.img (8GB), boot_a.img, vendor_boot_a.img, init_boot_a.img, dtb_a.img, dtbo_a.img, vbmeta_a.img (D5489649), metadata.img, dan additional_boot_chain\avbmeta_rs_a.img
- D:\porting-custom-rom\backup\20260727*232329\ — backup parsial saat hp root KernelSU (tanpa super): boot_a, dtbo_a, init_boot_a, logo, misc, metadata, avbmeta_rs_a, common_rs\*, l_modem/l*\*nv
  Materi kerja di D:\realme-c53-recovery\:
- 02_bahan\porting_full_slotAB\ — 45 partisi A/B (termasuk logo.img, misc.img bootonce-bootloader)
- 02_bahan\backup_utama\ — kernel/AVB: vbmeta_a.img (D5489649), vbmeta_system (93C24BF0), dtbo, dll
- 02_bahan\ready_to_flash\ — 4 image repair yang sudah diverifikasi: uboot_a E1BA264C, teecfg_a 0AA735C4, pm_sys_a D1D19ECE, common_rs1_a 211C6100 (cocok dengan device)
- 02_bahan\boot_chain_known_good\ — 9 image boot chain
- 02_bahan\readback_verifikasi\ — readback dari device = bukti semua partisi MATCH
  Catatan: uboot_a/teecfg_a/pm_sys_a/common_rs1_a tidak ada di backup original hp ini — yang terpakai dari ready_to_flash (ROM riset) tapi hasil readback-nya MATCH persis dengan device, jadi aman.
