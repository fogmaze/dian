@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem ============================================================
rem Copy this installer from USB to the local TEMP directory.
rem ============================================================

if /i not "%~1"=="--local-copy" (
    set "LOCAL_BAT=%TEMP%\DianInstaller_%RANDOM%_%RANDOM%.bat"

    echo.
    echo Copying installer to the local computer...

    copy /y "%~f0" "%LOCAL_BAT%" >nul 2>&1

    if errorlevel 1 (
        echo [ERROR] Failed to copy installer to:
        echo   "%LOCAL_BAT%"
        pause
        exit /b 1
    )

    rem Start the copied batch file from the local TEMP directory
    start "Dian Installer" /d "%TEMP%" "%ComSpec%" /d /c ""%LOCAL_BAT%" --local-copy"

    if errorlevel 1 (
        echo [ERROR] Failed to start the local installer.
        del /q "%LOCAL_BAT%" >nul 2>&1
        pause
        exit /b 1
    )

    exit /b 0
)

rem ============================================================
rem Everything below is running from the computer's TEMP folder.
rem The USB drive is no longer required.
rem ============================================================

cd /d "%TEMP%"

echo.
echo ============================================================
echo The installer is now running from the local computer.
echo USB can now be removed safely.
echo ============================================================
echo.

set "ZIP_URL=https://github.com/fogmaze/dian/releases/latest/download/dian.zip"

rem Download and extract to the current user's Desktop
set "BASE_DIR=%USERPROFILE%\Desktop"
set "ZIP_FILE=%BASE_DIR%\Dian.zip"

if not exist "%BASE_DIR%" (
    echo [ERROR] Desktop directory was not found:
    echo   "%BASE_DIR%"
    pause
    exit /b 1
)

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl.exe was not found.
    pause
    exit /b 1
)

where tar.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] tar.exe was not found.
    pause
    exit /b 1
)

echo Download directory:
echo   "%BASE_DIR%"

echo.
echo [1/3] Downloading...

curl.exe -L --fail --retry 3 --retry-delay 2 ^
    -o "%ZIP_FILE%" ^
    "%ZIP_URL%"

if errorlevel 1 (
    echo.
    echo [ERROR] Download failed.

    if exist "%ZIP_FILE%" (
        del /q "%ZIP_FILE%" >nul 2>&1
    )

    pause
    exit /b 1
)

if not exist "%ZIP_FILE%" (
    echo.
    echo [ERROR] ZIP file was not created:
    echo   "%ZIP_FILE%"
    pause
    exit /b 1
)

echo.
echo [2/3] Extracting...

tar.exe -xf "%ZIP_FILE%" -C "%BASE_DIR%"

if errorlevel 1 (
    echo.
    echo [ERROR] Extraction failed.
    echo ZIP file:
    echo   "%ZIP_FILE%"
    pause
    exit /b 1
)

del /q "%ZIP_FILE%" >nul 2>&1

echo.
echo [3/3] Running init.bat...

if exist "%BASE_DIR%\Dian\init.bat" (
    goto RUN_DIAN_INIT
)

if exist "%BASE_DIR%\init.bat" (
    goto RUN_ROOT_INIT
)

echo.
echo [ERROR] init.bat was not found.
echo Checked:
echo   "%BASE_DIR%\Dian\init.bat"
echo   "%BASE_DIR%\init.bat"
pause
exit /b 1


:RUN_DIAN_INIT
call "%BASE_DIR%\Dian\init.bat"
set "INIT_RESULT=%errorlevel%"
goto INIT_FINISHED


:RUN_ROOT_INIT
call "%BASE_DIR%\init.bat"
set "INIT_RESULT=%errorlevel%"
goto INIT_FINISHED


:INIT_FINISHED
echo.

if not "%INIT_RESULT%"=="0" (
    echo [ERROR] init.bat returned error code %INIT_RESULT%.
    pause
    exit /b %INIT_RESULT%
)

echo ============================================================
echo Installation completed successfully.
echo ============================================================
echo.

pause
exit /b 0
