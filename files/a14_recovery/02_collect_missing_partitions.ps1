# ============================================================
# 02_collect_missing_partitions.ps1
# Collect additional boot-chain partitions from old backups
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

$SourceRoot = "D:\porting-custom-rom\backup"

$DestinationRoot =
"D:\realme-c53-rom-backup\additional_boot_chain"

# ------------------------------------------------------------
# REQUIRED ADDITIONAL PARTITIONS
# Expected sizes are based on the FDL2 partition table.
# ------------------------------------------------------------

$RequiredPartitions = @(
    @{
        Name         = "uboot_a"
        ExpectedSize = 3MB
    },
    @{
        Name         = "sml_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "trustos_a"
        ExpectedSize = 6MB
    },
    @{
        Name         = "teecfg_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "hypervsior_a"
        ExpectedSize = 10MB
    },
    @{
        Name         = "pm_sys_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "vbmeta_system_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "vbmeta_vendor_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "vbmeta_system_ext_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "vbmeta_product_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "vbmeta_odm_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "avbmeta_rs_a"
        ExpectedSize = 1MB
    },
    @{
        Name         = "common_rs1_a"
        ExpectedSize = 8MB
    },
    @{
        Name         = "common_rs2_a"
        ExpectedSize = 16MB
    }
)

# ------------------------------------------------------------
# VALIDATION
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Source backup folder tidak ditemukan: $SourceRoot"
}

if (-not (Test-Path -LiteralPath $DestinationRoot)) {
    New-Item `
        -ItemType Directory `
        -Path $DestinationRoot `
        -Force | Out-Null
}

Write-Host ""
Write-Host "================================================"
Write-Host "COLLECT ADDITIONAL BOOT-CHAIN PARTITIONS"
Write-Host "================================================"
Write-Host ""
Write-Host "Source:"
Write-Host "  $SourceRoot"
Write-Host ""
Write-Host "Destination:"
Write-Host "  $DestinationRoot"
Write-Host ""

# ------------------------------------------------------------
# SEARCH AND COPY
# ------------------------------------------------------------

$Results = foreach ($Partition in $RequiredPartitions) {

    $PartitionName = $Partition.Name
    $ExpectedSize = [Int64]$Partition.ExpectedSize

    $DestinationFile =
    Join-Path `
        $DestinationRoot `
        "$PartitionName.img"

    # --------------------------------------------------------
    # If destination already exists, do not overwrite.
    # --------------------------------------------------------

    if (Test-Path -LiteralPath $DestinationFile) {

        $ExistingFile =
        Get-Item -LiteralPath $DestinationFile

        $Status = if (
            $ExistingFile.Length -eq $ExpectedSize
        ) {
            "ALREADY_EXISTS"
        }
        else {
            "EXISTS_SIZE_MISMATCH"
        }

        [PSCustomObject]@{
            Partition    = $PartitionName
            ExpectedSize = $ExpectedSize
            Source       = "-"
            Destination  = $DestinationFile
            ActualSize   = $ExistingFile.Length
            Status       = $Status
        }

        continue
    }

    # --------------------------------------------------------
    # Search possible image names.
    #
    # Supports:
    # uboot_a.img
    # uboot_a.bin
    # uboot_a
    # --------------------------------------------------------

    $Candidates =
    Get-ChildItem `
        -LiteralPath $SourceRoot `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.BaseName -eq $PartitionName
    }

    if (-not $Candidates) {

        [PSCustomObject]@{
            Partition    = $PartitionName
            ExpectedSize = $ExpectedSize
            Source       = "-"
            Destination  = $DestinationFile
            ActualSize   = 0
            Status       = "NOT_FOUND"
        }

        continue
    }

    # --------------------------------------------------------
    # Prefer a candidate with the exact expected size.
    # --------------------------------------------------------

    $ExactCandidate =
    $Candidates |
    Where-Object {
        $_.Length -eq $ExpectedSize
    } |
    Select-Object -First 1

    if (-not $ExactCandidate) {

        $FoundFiles =
        $Candidates |
        ForEach-Object {
            "$($_.FullName) [$($_.Length) bytes]"
        }

        [PSCustomObject]@{
            Partition    = $PartitionName
            ExpectedSize = $ExpectedSize
            Source       = ($FoundFiles -join " | ")
            Destination  = $DestinationFile
            ActualSize   = 0
            Status       = "FOUND_BUT_SIZE_MISMATCH"
        }

        continue
    }

    # --------------------------------------------------------
    # Copy without overwriting.
    # --------------------------------------------------------

    Copy-Item `
        -LiteralPath $ExactCandidate.FullName `
        -Destination $DestinationFile `
        -ErrorAction Stop

    $CopiedFile =
    Get-Item `
        -LiteralPath $DestinationFile

    $Status = if (
        $CopiedFile.Length -eq $ExpectedSize
    ) {
        "COPIED_OK"
    }
    else {
        "COPY_SIZE_MISMATCH"
    }

    [PSCustomObject]@{
        Partition    = $PartitionName
        ExpectedSize = $ExpectedSize
        Source       = $ExactCandidate.FullName
        Destination  = $DestinationFile
        ActualSize   = $CopiedFile.Length
        Status       = $Status
    }
}

# ------------------------------------------------------------
# DISPLAY REPORT
# ------------------------------------------------------------

Write-Host ""
Write-Host "================================================"
Write-Host "RESULT"
Write-Host "================================================"
Write-Host ""

$Results |
Select-Object `
    Partition,
Status,
ExpectedSize,
ActualSize,
Source |
Format-Table `
    -AutoSize

# ------------------------------------------------------------
# SAVE REPORTS
# ------------------------------------------------------------

$CsvReport =
Join-Path `
    $DestinationRoot `
    "02_collect_missing_partitions_report.csv"

$TextReport =
Join-Path `
    $DestinationRoot `
    "02_collect_missing_partitions_report.txt"

$Results |
Export-Csv `
    -LiteralPath $CsvReport `
    -NoTypeInformation `
    -Encoding UTF8

$Results |
Format-Table `
    Partition,
Status,
ExpectedSize,
ActualSize,
Source,
Destination `
    -AutoSize |
Out-String |
Set-Content `
    -LiteralPath $TextReport `
    -Encoding UTF8

# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------

$CopiedCount = @(
    $Results |
    Where-Object {
        $_.Status -eq "COPIED_OK"
    }
).Count

$ExistsCount = @(
    $Results |
    Where-Object {
        $_.Status -eq "ALREADY_EXISTS"
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
        $_.Status -like "*SIZE_MISMATCH*"
    }
).Count

Write-Host ""
Write-Host "================================================"
Write-Host "SUMMARY"
Write-Host "================================================"
Write-Host "COPIED_OK              : $CopiedCount"
Write-Host "ALREADY_EXISTS         : $ExistsCount"
Write-Host "NOT_FOUND              : $NotFoundCount"
Write-Host "SIZE_MISMATCH          : $SizeMismatchCount"
Write-Host ""
Write-Host "Destination:"
Write-Host "  $DestinationRoot"
Write-Host ""
Write-Host "CSV report:"
Write-Host "  $CsvReport"
Write-Host ""
Write-Host "TXT report:"
Write-Host "  $TextReport"
Write-Host ""
Write-Host "Tidak ada partisi yang ditulis ke HP."
Write-Host "Script hanya mencari dan menyalin file backup."