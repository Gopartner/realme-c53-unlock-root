param(
    [int]$MaxPayloadAttempts = 3
)

$ErrorActionPreference = 'Continue'
$SprdDir = $PSScriptRoot
$SpdDump = Join-Path $SprdDir 'spd_dump.exe'
$Fdl1    = Join-Path $SprdDir 'fdl1-sign.bin'
$Fdl2    = Join-Path $SprdDir 'lk-fdl2-sign.bin'
$SplUnlock = Join-Path $SprdDir 'spl-unlock.bin'
$Cboot   = Join-Path $SprdDir 'fdl2-cboot.bin'
$PatchedSpl = Join-Path $SprdDir 'u-boot-spl-16k-sign.bin'
$UbootBak = Join-Path $SprdDir 'uboot_bak.bin'
$MiscWipe = Join-Path $SprdDir 'misc-wipe.bin'
$MBin    = Join-Path $SprdDir 'm.bin'
$LogFile = 'D:\Realme-C-project\realme-c53-unlock-root\output\logs\redo-unlock.log'
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
    Write-Log '>>> CABUT kabel USB sekarang...'
    $deadline = (Get-Date).AddSeconds($PortTimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (-not (Test-SPRDPortPresent)) { Write-Log 'Port SPRD hilang. OK.'; return $true }
        Start-Sleep -Seconds 2
    }
    Write-Log 'TIMEOUT tunggu port hilang.'; return $false
}

function Wait-SPRDAppear {
    Write-Log '>>> PASANG kabel USB (tahan Vol Up+Down) sampai COM muncul...'
    $deadline = (Get-Date).AddSeconds($PortTimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-SPRDPortPresent) { Write-Log 'Port SPRD terdeteksi. OK.'; return $true }
        Start-Sleep -Seconds 2
    }
    Write-Log 'TIMEOUT tunggu port muncul.'; return $false
}

function Wait-ForFreshReplug {
    Write-Log '--- Siapkan sesi BROM FRESH: re-plug USB ---'
    Wait-SPRDDisappear | Out-Null
    Wait-SPRDAppear | Out-Null
}

function Invoke-Spd([string[]]$ArgsList, [string]$LogLabel) {
    $output = & $SpdDump @ArgsList 2>&1
    $text = ($output | Out-String)
    Add-Content -LiteralPath $LogFile -Value "`n--- $LogLabel ---`n$text"
    try { Write-Host $text } catch {}
    return $text
}

# Session base: load A14 FDL then exec commands
function New-Base {
    @('--wait','300','exec_addr','0x65015f08','fdl',$Fdl1,'0x65000800','fdl',$Fdl2,'0x9efffe00','exec')
}

if (-not (Test-Path -LiteralPath $SpdDump)) { Write-Error "spd_dump tidak ada: $SpdDump"; exit 1 }

Write-Log '===== REDO UNLOCK (CVE-2022-38694) A14 ====='
Write-Log 'Siapkan HP: masuk SPRD mode. Setiap sesi harus re-plug USB.'

# ---------- Step A: write cboot to uboot ----------
Wait-ForFreshReplug
$base = New-Base
$out = Invoke-Spd ($base + @('w','uboot',$Cboot,'reset')) 'STEP A: write cboot uboot'
if ($out -match 'Write Part Done.*uboot') {
    Write-Log 'STEP A OK: cboot ditulis ke uboot.'
} else {
    Write-Log 'STEP A FAIL: cboot tidak tertulis. Hentikan.'
    exit 1
}

# ---------- Step B: run unlock payload ----------
$payloadRan = $false
for ($i = 1; $i -le $MaxPayloadAttempts; $i++) {
    Wait-ForFreshReplug
    $out = Invoke-Spd @('exec_addr','0x65015f08','fdl',$SplUnlock,'0x65000800') ("STEP B: payload spl-unlock percobaan $i")
    Write-Log ("Payload attempt {0}: SEND ke 0x65000800." -f $i)
    if ($out -match 'SEND.*spl-unlock') { $payloadRan = $true }
    Start-Sleep -Seconds 8
}
if (-not $payloadRan) { Write-Log 'WARNING: payload mungkin tidak terkirim.' }

# ---------- Step C: verify miscdata ----------
Wait-ForFreshReplug
$out = Invoke-Spd ($base + @('read_part','miscdata','8192','64',$MBin)) 'STEP C: verify miscdata'
$nonzero = 0
if (Test-Path -LiteralPath $MBin) {
    $bytes = [System.IO.File]::ReadAllBytes($MBin)
    $nonzero = @($bytes | Where-Object { $_ -ne 0 }).Count
    Write-Log ("miscdata: {0}/64 non-zero | hex: {1}" -f $nonzero, (($bytes | ForEach-Object { $_.ToString('x2') }) -join ' '))
} else {
    Write-Log 'm.bin tidak terbaca!'
}

if ($nonzero -gt 0) {
    Write-Log '>>> RESULT: UNLOCKED! Lanjut restore.'
} else {
    Write-Log '>>> RESULT: miscdata masih 0 (locked). Payload belum efektif.'
    Write-Log 'Coba ulang script dengan kondisi device benar di mode cboot.'
    exit 2
}

# ---------- Step D: restore uboot + wipe misc ----------
Wait-ForFreshReplug
$out = Invoke-Spd ($base + @('w','uboot',$UbootBak,'w','misc',$MiscWipe,'reset')) 'STEP D: restore uboot + wipe misc'
if ($out -match 'Write Part Done.*uboot' -and $out -match 'Write Part Done.*misc') {
    Write-Log 'STEP D OK: uboot asli + misc di-restore.'
} else {
    Write-Log 'STEP D WARNING: cek log.'
}

Write-Log '===== SELESAI ====='
Write-Log 'Device reboot. Masuk fastboot, lalu flash magisk_patched_boot_a14.img ke boot_a & boot_b.'
