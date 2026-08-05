param(
  [string]$ReadbackDir = "$PSScriptRoot\..\02_bahan\readback_verifikasi"
)

$known = @{
  'uboot_a'       = @('E1BA264C7499188E6E23F017FAF6F574069247EA2E2AAE5AA357BCF5CB35F3FB','3145728')
  'sml_a'         = @('168186088C4C04E175EFAD36B6C4855A50E480DE883115E3D09B26A61899B39D','1048576')
  'trustos_a'     = @('3EA1F3DA9D157408E3D47DCE6B2BC5A9EEF3777D81B65BABBFBB6FBA7A3A7E2B','6291456')
  'teecfg_a'      = @('0AA735C48121109E39359284B9B848B8EF651D9B661CD71C7B25EF617A4D1F6F','1048576')
  'pm_sys_a'      = @('D1D19ECE05BFC7633301165A66FEEBEEB492072501E30BFDA49695F5B4F1D603','1048576')
  'common_rs1_a'  = @('211C61001C4298F4CACC35B22FB3F19F7B4B41D18598CA33B5BED8E555FB9B03','8388608')
  'vbmeta_a'      = @('D54896497690E05999394A2D3BD46C2F23ACAB8049BBB70A20CE3FABCBDEF665','1048576')
  'boot_a'        = @('74206B0EA8659391F9B4BB70CB1FB3E2ECA4C35480DD4CD2BE034BB37F597512','67108864')
  'vendor_boot_a' = @('EA8D0317E609EBF24E14F80338AF4643492274C86519FF44768D6780E413E27A','104857600')
}

Write-Host "======================================================"
Write-Host "VERIFIKASI READBACK vs HASH KNOWN-GOOD"
Write-Host "Readback dir: $ReadbackDir"
Write-Host "======================================================"

$any = $false
foreach ($p in $known.Keys) {
  $candidates = @(
    (Join-Path $ReadbackDir "$p.bin"),
    (Join-Path $ReadbackDir "$p.img"),
    (Join-Path $ReadbackDir "check_$p.bin"),
    (Join-Path $ReadbackDir "$p`_check.bin"),
    (Join-Path $ReadbackDir "$p`_verify.bin")
  )
  $file = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $file) { continue }
  $any = $true
  $actual = (Get-FileHash $file -Algorithm SHA256).Hash
  $expected = $known[$p][0]
  $match = if ($actual -eq $expected) { "MATCH" } else { "MISMATCH" }
  $line = "{0,-16} {1,-9} {2}" -f $p, $match, $actual
  Write-Host $line
}

if (-not $any) {
  Write-Host "Tidak ada file readback ditemukan di $ReadbackDir"
  Write-Host "Letakkan hasil spd_dump read_part di folder tersebut dengan nama <partisi>.bin"
}
