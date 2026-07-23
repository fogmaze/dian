@echo off
setlocal

set "ZIP_URL=https://github.com/fogmaze/dian/releases/latest/download/Dian.tar.gz"

rem Convert the batch-file directory into a path without trailing backslash
for %%I in ("%~dp0.") do set "BASE_DIR=%%~fI"

set "ZIP_FILE=%BASE_DIR%\Dian.tar.gz"

echo.
echo [1/3] Downloading...

curl.exe -L --fail --retry 3 --retry-delay 2 ^
    -o "%ZIP_FILE%" ^
    "%ZIP_URL%"

if errorlevel 1 (
    echo [ERROR] Download failed.
    if exist "%ZIP_FILE%" del /q "%ZIP_FILE%"
    pause
    exit /b 1
)

if not exist "%ZIP_FILE%" (
    echo [ERROR] ZIP file was not created.
    pause
    exit /b 1
)

echo.
echo [2/3] Extracting...

tar.exe -xzf "%ZIP_FILE%" -C "%BASE_DIR%"

if errorlevel 1 (
    echo [ERROR] Extraction failed.
    pause
    exit /b 1
)

del /q "%ZIP_FILE%" >nul 2>&1

echo.
echo [3/3] Running init.bat...

if exist "%BASE_DIR%\Dian\init.bat" (
    call "%BASE_DIR%\Dian\init.bat"
    exit /b %errorlevel%
)

if exist "%BASE_DIR%\init.bat" (
    call "%BASE_DIR%\init.bat"
    exit /b %errorlevel%
)

echo [ERROR] init.bat was not found.
echo Checked:
echo   "%BASE_DIR%\Dian\init.bat"
echo   "%BASE_DIR%\init.bat"
pause
exit /b 1
