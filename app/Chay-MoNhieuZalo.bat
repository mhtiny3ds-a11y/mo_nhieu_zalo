@echo off
:: Chay app MoNhieuZalo khong can build .exe
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0MoNhieuZalo.ps1"
