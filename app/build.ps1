<#
  Build MoNhieuZalo.ps1 thanh MoNhieuZalo.exe bang module ps2exe.
  Chay trong PowerShell:  powershell -ExecutionPolicy Bypass -File .\build.ps1
#>
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host 'Dang cai module ps2exe (chi can mot lan)...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    }
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe

$params = @{
    inputFile   = Join-Path $here 'MoNhieuZalo.ps1'
    outputFile  = Join-Path $here 'MoNhieuZalo.exe'
    noConsole   = $true
    title       = 'Mo Nhieu Zalo'
    description = 'Mo nhieu tai khoan Zalo PC cung luc'
    product     = 'MoNhieuZalo'
    version     = '1.0.0'
}
$icon = Join-Path $here 'icon.ico'
if (Test-Path $icon) { $params.iconFile = $icon }

Invoke-ps2exe @params
Write-Host "Xong: $($params.outputFile)"
