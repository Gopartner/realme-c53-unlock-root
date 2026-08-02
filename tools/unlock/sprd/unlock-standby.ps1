param(
    [switch]$RunUnlockPayload
)

$ErrorActionPreference = 'Continue'
$SprdDir = 'D:\Realme-C-project\realme-c53-unlock-root\tools\unlock\sprd'
$SpdDump = Join-Path $SprdDir 'spd_dump.exe'
$Fdl1    = Join-Path $SprdDir 'fdl1-sign.bin'
$Fdl2    = Join-Path $SprdDir 'lk-fdl2-sign.bin'
$SplUnlock = Join-Path $SprdDir 'spl-unlock.bin'
$PatchedSpl = Join-Path $SprdDir 'u-boot-spl-16k-sign.bin'
$UbootBak = Join-Path $SprdDir 'uboot_bak.bin'
$MiscWipe = Join-Path $SprdDir 'misc-wipe.bin'
$MBin    = Join-Path $SprdDir 'm.bin'
$LogFile = 'D:\Realme-C-project\realme-c53-unlock-root\output\logs\standby-log.txt'
$PortTimeoutSec = 300

function Write-Log([string]$msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    Write-Host $line
    Add-Content -LiteralPath $LogFile -Value $line
}

function Test-SPRDPortPresent {
    [bool](Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.FriendlyName -match 'SPRD' })
}

function Wait-SPRDDisappear {
    Write-Log 'Tunggu port SPRD HILANG (cabut kabel USB)...'
    $deadline = (Get-Date).AddSeconds($PortTimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (-not (Test-SPRDPortPresent)) {
            Write-Log 'Port SPRD hilang. OK.'
            return $true
        }
        Start-Sleep -Seconds 2
    }
    Write-Log 'TIMEOUT tunggu port hilang.'
    return $false
}

function Wait-SPRDAppear {
    Write-Log 'Tunggu port SPRD MUNCUL (colok kabel USB sambil tahan Vol Up+Down)...'
    $deadline = (Get-Date).AddSeconds($PortTimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-SPRDPortPresent) {
            Write-Log 'Port SPRD terdeteksi. OK.'
            return $true
        }
        Start-Sleep -Seconds 2
    }
    Write-Log 'TIMEOUT tunggu port muncul.'
    return $false
}

function Invoke-SpdStep([string]$Label, [string[]]$SpdArgs, [bool]$TreatCheckBaudAsOk) {
    if (Test-SPRDPortPresent) {
        Write-Log 'Port SPRD ada, langsung coba.'
    } else {
        Wait-SPRDAppear | Out-Null
    }
    $attempt = 0
    while ($true) {
        $attempt++
        Write-Log ("=== {0} (percobaan {1}) ===" -f $Label, $attempt)
        $output = & $SpdDump @SpdArgs 2>&1
        $text = ($output | Out-String)
        Add-Content -LiteralPath $LogFile -Value $text
        try { Write-Host $text } catch {}
        if ($text -match 'CHECK_BAUD FAIL' -and -not $TreatCheckBaudAsOk) {
            Write-Log 'CHECK_BAUD FAIL - device belum siap BROM. Cabut & pasang ulang USB, ulangi.'
            Wait-SPRDDisappear | Out-Null
            Wait-SPRDAppear | Out-Null
            continue
        }
        Write-Log "$Label SELESAI"
        return $text
    }
}

function New-BaseArgs {
    @('--wait','300','exec_addr','0x65015f08','fdl',$Fdl1,'0x65000800','fdl',$Fdl2,'0x9efffe00','exec')
}

if (-not (Test-Path -LiteralPath $SpdDump)) {
    Write-Error "spd_dump.exe tidak ditemukan: $SpdDump"
    exit 1
}

Write-Log '===== UNLOCK STANDBY SCRIPT (A14) ====='
if ($RunUnlockPayload) {
    $payloadArgs = @('exec_addr','0x65015f08','fdl',$SplUnlock,'0x65000800')
    $out = Invoke-SpdStep 'PAYLOAD spl-unlock.bin' $payloadArgs $true
    Write-Log 'Payload dijalankan. CHECK_BAUD FAIL setelahnya = NORMAL (device reboot).'
}

$base = New-BaseArgs
$combArgs = $base + @('read_part','miscdata','8192','64',$MBin,
    'r','boot',
    'w','splloader',$PatchedSpl,
    'w','uboot',$UbootBak,
    'w','misc',$MiscWipe,
    'reset')
$out = Invoke-SpdStep 'VERIFY miscdata + RESTORE splloader/uboot/misc' $combArgs $false

$nonzero = 0
if (Test-Path -LiteralPath $MBin) {
    $bytes = [System.IO.File]::ReadAllBytes($MBin)
    $nonzero = @($bytes | Where-Object { $_ -ne 0 }).Count
    Write-Log ("miscdata (64 B): {0} byte non-zero / {1} total" -f $nonzero, $bytes.Length)
    Write-Log ("hex: {0}" -f (($bytes | ForEach-Object { $_.ToString('x2') }) -join ' '))
} else {
    Write-Log 'm.bin tidak terbaca!'
}
if ($nonzero -gt 0) {
    Write-Log 'RESULT: UNLOCKED (miscdata non-zero).'
} else {
    Write-Log 'RESULT: miscdata masih 0. Patched SPL tetap menjadi unlock permanen.'
}

if ($out -match 'Write Part Done.*splloader' -and $out -match 'Write Part Done.*uboot') {
    Write-Log 'RESTORE OK: splloader + uboot + misc tertulis.'
} else {
    Write-Log 'WARNING: cek log, ada yang tidak tertulis.'
}

Write-Log '===== SCRIPT SELESAI ====='
Write-Log 'Device boot normal (unlocked via patched SPL).'
Write-Log 'Lanjut: masuk fastboot, lalu flash boot_a & boot_b.'
