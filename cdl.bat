```bat
@echo off
setlocal

set "ZIP_URL=https://drive.google.com/uc?export=download&id=14IiXyc_DjK5pj2jkhWGmySuAhX9yc9Lb"

rem Directory containing this batch file
set "BASE_DIR=%~dp0"

rem Downloaded ZIP path
set "ZIP_FILE=%BASE_DIR%Dian.zip"

echo.
echo [1/3] Downloading...

curl.exe -L --fail --retry 3 -o "%ZIP_FILE%" "%ZIP_URL%"

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

tar.exe -xf "%ZIP_FILE%" -C "%BASE_DIR%"

if errorlevel 1 (
    echo [ERROR] Extraction failed.
    pause
    exit /b 1
)

del /q "%ZIP_FILE%" >nul 2>&1

echo.
echo [3/3] Running init.bat...

if exist "%BASE_DIR%Dian\init.bat" (
    call "%BASE_DIR%Dian\init.bat"
    exit /b
)

if exist "%BASE_DIR%init.bat" (
    call "%BASE_DIR%init.bat"
    exit /b
)

echo [ERROR] init.bat was not found.
pause
exit /b 1
```

