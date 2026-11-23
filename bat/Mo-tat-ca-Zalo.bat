@echo off
setlocal
:: Tao boi cong cu "Mo Nhieu Zalo" - moi tai khoan dung thu muc du lieu rieng
set "ZALO_EXE=%LOCALAPPDATA%\Programs\Zalo\Zalo.exe"
set "BASE=%USERPROFILE%\ZaloMulti"
if not exist "%ZALO_EXE%" goto :notfound

:: Zalo chinh
start "" "%ZALO_EXE%"
timeout /t 3 /nobreak >nul
:: Cac tai khoan phu
call :open "TaiKhoan2"
call :open "TaiKhoan3"
call :open "TaiKhoan4"
exit /b

:open
setlocal
set "H=%BASE%\%~1"
if not exist "%H%\AppData\Roaming" mkdir "%H%\AppData\Roaming"
if not exist "%H%\AppData\Local" mkdir "%H%\AppData\Local"
set "USERPROFILE=%H%"
set "APPDATA=%H%\AppData\Roaming"
set "LOCALAPPDATA=%H%\AppData\Local"
start "" "%ZALO_EXE%"
endlocal
timeout /t 3 /nobreak >nul
exit /b

:notfound
echo Khong tim thay Zalo tai: "%ZALO_EXE%"
echo Hay mo file nay bang Notepad va sua dong ZALO_EXE cho dung duong dan.
pause
exit /b 1
