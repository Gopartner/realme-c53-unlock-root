# ============================================================
# 03_validate_full_backup.ps1
#
# Validasi seluruh koleksi backup Realme C53 slot A.
#
# Pemeriksaan:
# - File tersedia
# - Ukuran file sesuai ukuran partisi
# - SHA-256 dihitung
# - Laporan CSV dan TXT dibuat
#
# TIDAK MENULIS APA PUN KE HP.
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Lokasi folder
# ------------------------------------------------------------

$MainBackupDir = "D:\realme-c53-rom-backup"

$AdditionalDir = Join-Path `
    $MainBackupDir `
    "additional_boot_chain"

$VbmetaDir = `
    "D:\Realme-C-project\07-verify_readback-FDL2\additional_partitions"

# ------------------------------------------------------------
# Daftar partisi yang harus divalidasi
# ------------------------------------------------------------

$Partitions = @(

    # ========================================================
    # Backup utama
    # ========================================================

    @{
        Partition = "boot_a"
        FileName  = "boot_a.img"
        Size      = 67108864
        Location  = $MainBackupDir
    },

    @{
        Partition = "vendor_boot_a"
        FileName  = "vendor_boot_a.img"
        Size      = 104857600
        Location  = $MainBackupDir
    },

    @{
        Partition = "init_boot_a"
        FileName  = "init_boot_a.img"
        Size      = 8388608
        Location  = $MainBackupDir
    },

    @{
        Partition = "dtb_a"
        FileName  = "dtb_a.img"
        Size      = 8388608
        Location  = $MainBackupDir
    },

    @{
        Partition = "dtbo_a"
        FileName  = "dtbo_a.img"
        Size      = 8388608
        Location  = $MainBackupDir
    },

    @{
        Partition = "vbmeta_a"
        FileName  = "vbmeta_a.img"
        Size      = 1048576
        Location  = $MainBackupDir
    },

    @{
        Partition = "metadata"
        FileName  = "metadata.img"
        Size      = 67108864
        Location  = $MainBackupDir
    },

    @{
        Partition = "super"
        FileName  = "super.img"
        Size      = 8388608000
        Location  = $MainBackupDir
    },

    # ========================================================
    # Additional boot-chain
    # ========================================================

    @{
        Partition = "uboot_a"
        FileName  = "uboot_a.bin"
        Size      = 3145728
        Location  = $AdditionalDir
    },

    @{
        Partition = "sml_a"
        FileName  = "sml_a.bin"
        Size      = 1048576
        Location  = $AdditionalDir
    },

    @{
        Partition = "trustos_a"
        FileName  = "trustos_a.bin"
        Size      = 6291456
        Location  = $AdditionalDir
    },

    @{
        Partition = "teecfg_a"
        FileName  = "teecfg_a.bin"
        Size      = 1048576
        Location  = $AdditionalDir
    },

    @{
        Partition = "hypervsior_a"
        FileName  = "hypervsior_a.img"
        Size      = 10485760
        Location  = $AdditionalDir
    },

    @{
        Partition = "pm_sys_a"
        FileName  = "pm_sys_a.bin"
        Size      = 1048576
        Location  = $AdditionalDir
    },

    @{
        Partition = "common_rs1_a"
        FileName  = "common_rs1_a.bin"
        Size      = 8388608
        Location  = $AdditionalDir
    },

    @{
        Partition = "common_rs2_a"
        FileName  = "common_rs2_a.img"
        Size      = 16777216
        Location  = $AdditionalDir
    },

    @{
        Partition = "avbmeta_rs_a"
        FileName  = "avbmeta_rs_a.img"
        Size      = 1048576
        Location  = $AdditionalDir
    },

    # ========================================================
    # Additional vbmeta readback
    # ========================================================

    @{
        Partition = "vbmeta_system_a"
        FileName  = "vbmeta_system_a.bin"
        Size      = 1048576
        Location  = $VbmetaDir
    },

    @{
        Partition = "vbmeta_vendor_a"
        FileName  = "vbmeta_vendor_a.bin"
        Size      = 1048576
        Location  = $VbmetaDir
    },

    @{
        Partition = "vbmeta_system_ext_a"
        FileName  = "vbmeta_system_ext_a.bin"
        Size      = 1048576
        Location  = $VbmetaDir
    },

    @{
        Partition = "vbmeta_product_a"
        FileName  = "vbmeta_product_a.bin"
        Size      = 1048576
        Location  = $VbmetaDir
    },

    @{
        Partition = "vbmeta_odm_a"
        FileName  = "vbmeta_odm_a.bin"
        Size      = 1048576
        Location  = $VbmetaDir
    }
)

# ------------------------------------------------------------
# Mulai validasi
# ------------------------------------------------------------

Write-Host ""
Write-Host "================================================"
Write-Host "VALIDATE FULL REALME C53 BACKUP"
Write-Host "================================================"
Write-Host ""

$Results = foreach ($Item in $Partitions) {

    $FilePath = Join-Path `
        $Item.Location `
        $Item.FileName

    Write-Host "Checking: $($Item.Partition)"

    if (-not (Test-Path -LiteralPath $FilePath)) {

        [PSCustomObject]@{
            Partition    = $Item.Partition
            FileName     = $Item.FileName
            ExpectedSize = [Int64]$Item.Size
            ActualSize   = [Int64]0
            Status       = "NOT_FOUND"
            SHA256       = "-"
            Path         = $FilePath
        }

        continue
    }

    $FileInfo = Get-Item `
        -LiteralPath $FilePath

    $ActualSize = [Int64]$FileInfo.Length

    if ($ActualSize -ne [Int64]$Item.Size) {

        [PSCustomObject]@{
            Partition    = $Item.Partition
            FileName     = $Item.FileName
            ExpectedSize = [Int64]$Item.Size
            ActualSize   = $ActualSize
            Status       = "SIZE_MISMATCH"
            SHA256       = "-"
            Path         = $FilePath
        }

        continue
    }

    $Hash = (
        Get-FileHash `
            -LiteralPath $FilePath `
            -Algorithm SHA256
    ).Hash

    [PSCustomObject]@{
        Partition    = $Item.Partition
        FileName     = $Item.FileName
        ExpectedSize = [Int64]$Item.Size
        ActualSize   = $ActualSize
        Status       = "VALID"
        SHA256       = $Hash
        Path         = $FilePath
    }
}

# ------------------------------------------------------------
# Tampilkan hasil
# ------------------------------------------------------------

Write-Host ""

$Results |
Format-Table `
    Partition,
Status,
ExpectedSize,
ActualSize,
FileName `
    -AutoSize

# ------------------------------------------------------------
# Hitung ringkasan
# ------------------------------------------------------------

$ValidCount = @(
    $Results |
    Where-Object {
        $_.Status -eq "VALID"
    }
).Count

$NotFoundCount = @(
    $Results |
    Where-Object {
        $_.Status -eq "NOT_FOUND"
    }
).Count

$SizeMismatchCount = @(
    $Results |
    Where-Object {
        $_.Status -eq "SIZE_MISMATCH"
    }
).Count

# ------------------------------------------------------------
# Simpan laporan
# ------------------------------------------------------------

$CsvReport = Join-Path `
    $MainBackupDir `
    "03_full_backup_validation_report.csv"

$TxtReport = Join-Path `
    $MainBackupDir `
    "03_full_backup_validation_report.txt"

$Results |
Export-Csv `
    -Path $CsvReport `
    -NoTypeInformation `
    -Encoding UTF8

$Results |
Format-Table `
    Partition,
Status,
ExpectedSize,
ActualSize,
FileName,
SHA256,
Path `
    -AutoSize |
Out-String |
Set-Content `
    -Path $TxtReport `
    -Encoding UTF8

# ------------------------------------------------------------
# Ringkasan akhir
# ------------------------------------------------------------

Write-Host ""
Write-Host "================================================"
Write-Host "VALIDASI SELESAI"
Write-Host "================================================"
Write-Host "VALID         : $ValidCount"
Write-Host "NOT_FOUND     : $NotFoundCount"
Write-Host "SIZE_MISMATCH : $SizeMismatchCount"
Write-Host ""
Write-Host "Laporan CSV:"
Write-Host $CsvReport
Write-Host ""
Write-Host "Laporan TXT:"
Write-Host $TxtReport
Write-Host ""

if (
    $NotFoundCount -eq 0 -and
    $SizeMismatchCount -eq 0
) {
    Write-Host "STATUS AKHIR: SEMUA FILE VALID"
}
else {
    Write-Host "STATUS AKHIR: MASIH ADA FILE BERMASALAH"
}