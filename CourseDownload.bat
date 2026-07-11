
@echo off
chcp 65001 >nul
setlocal

rem ZIP 直接下載連結
set "ZIP_URL=https://drive.google.com/uc?export=download&id=14IiXyc_DjK5pj2jkhWGmySuAhX9yc9Lb"

rem install.bat 所在資料夾
set "BASE_DIR=%~dp0"

rem ZIP 下載位置
set "ZIP_FILE=%BASE_DIR%Dian.zip"

echo.
echo [1/3] 正在下載...

curl.exe -L --fail -o "%ZIP_FILE%" "%ZIP_URL%"

if errorlevel 1 (
    echo [錯誤] 下載失敗。
    pause
    exit /b 1
)

echo.
echo [2/3] 正在解壓縮...

tar.exe -xf "%ZIP_FILE%" -C "%BASE_DIR%"

if errorlevel 1 (
    echo [錯誤] 解壓縮失敗。
    pause
    exit /b 1
)

echo.
echo [3/3] 正在執行 init.bat...

if exist "%BASE_DIR%Dian\init.bat" (
    call "%BASE_DIR%Dian\init.bat"
    exit /b %errorlevel%
)

if exist "%BASE_DIR%init.bat" (
    call "%BASE_DIR%init.bat"
    exit /b %errorlevel%
)

echo [錯誤] 找不到 init.bat。
pause
exit /b 1

