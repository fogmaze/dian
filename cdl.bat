@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem ============================================================
rem If this is already the local copy, begin installation
rem ============================================================

if /i "%~1"=="--local-copy" goto LOCAL_INSTALL


rem ============================================================
rem Copy the installer from USB to the local TEMP directory
rem ============================================================

set "LOCAL_BAT=%TEMP%\DianInstaller_%RANDOM%_%RANDOM%.bat"
set "LAUNCHER=%TEMP%\DianLauncher_%RANDOM%_%RANDOM%.cmd"

echo.
echo Copying installer to the local computer...

copy /y "%~f0" "%LOCAL_BAT%" >nul 2>&1

if errorlevel 1 goto COPY_FAILED

if not exist "%LOCAL_BAT%" goto COPY_FAILED


rem ============================================================
rem Create a launcher that keeps the window open
rem ============================================================

> "%LAUNCHER%" echo @echo off
>>"%LAUNCHER%" echo title Dian Installer
>>"%LAUNCHER%" echo echo Starting Dian installer...
>>"%LAUNCHER%" echo echo.
>>"%LAUNCHER%" echo call "%LOCAL_BAT%" --local-copy
>>"%LAUNCHER%" echo echo.
>>"%LAUNCHER%" echo echo Installer process has ended.
>>"%LAUNCHER%" echo echo You may review the messages above.
>>"%LAUNCHER%" echo echo.
>>"%LAUNCHER%" echo pause

if not exist "%LAUNCHER%" goto LAUNCHER_FAILED

echo Starting the local installer...

start "Dian Installer" /D "%TEMP%" "%ComSpec%" /d /c call "%LAUNCHER%"

if errorlevel 1 goto START_FAILED

exit /b 0


:COPY_FAILED
echo.
echo [ERROR] Failed to copy the installer.
echo.
echo Source:
echo   "%~f0"
echo.
echo Destination:
echo   "%LOCAL_BAT%"
echo.
pause
exit /b 1


:LAUNCHER_FAILED
echo.
echo [ERROR] Failed to create the local launcher.
echo.
echo Launcher:
echo   "%LAUNCHER%"
echo.
pause
exit /b 1


:START_FAILED
echo.
echo [ERROR] Failed to start the local installer.
echo.
echo Launcher:
echo   "%LAUNCHER%"
echo.
pause
exit /b 1


rem ============================================================
rem Local installation starts here
rem ============================================================

:LOCAL_INSTALL

cd /d "%TEMP%"

echo.
echo ============================================================
echo The installer is now running from the local computer.
echo You can now remove the USB drive.
echo ============================================================
echo.

set "ZIP_URL=https://github.com/fogmaze/dian/releases/latest/download/dian.zip"

rem Download and extract to the current user's Desktop
set "BASE_DIR=%USERPROFILE%\Desktop"
set "ZIP_FILE=%BASE_DIR%\Dian.zip"

if not exist "%BASE_DIR%" (
    echo [ERROR] Desktop directory was not found:
    echo   "%BASE_DIR%"
    exit /b 1
)

where curl.exe >nul 2>&1

if errorlevel 1 (
    echo [ERROR] curl.exe was not found.
    exit /b 1
)

where tar.exe >nul 2>&1

if errorlevel 1 (
    echo [ERROR] tar.exe was not found.
    exit /b 1
)

echo Download directory:
echo   "%BASE_DIR%"

echo.
echo [1/3] Downloading...

if exist "%ZIP_FILE%" (
    del /q "%ZIP_FILE%" >nul 2>&1
)

curl.exe -L --fail --retry 3 --retry-delay 2 ^
    -o "%ZIP_FILE%" ^
    "%ZIP_URL%"

if errorlevel 1 (
    echo.
    echo [ERROR] Download failed.

    if exist "%ZIP_FILE%" (
        del /q "%ZIP_FILE%" >nul 2>&1
    )

    exit /b 1
)

if not exist "%ZIP_FILE%" (
    echo.
    echo [ERROR] ZIP file was not created:
    echo   "%ZIP_FILE%"
    exit /b 1
)

echo.
echo [2/3] Extracting...

tar.exe -xf "%ZIP_FILE%" -C "%BASE_DIR%"

if errorlevel 1 (
    echo.
    echo [ERROR] Extraction failed.
    echo.
    echo ZIP file:
    echo   "%ZIP_FILE%"
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
echo.
echo Checked:
echo   "%BASE_DIR%\Dian\init.bat"
echo   "%BASE_DIR%\init.bat"
exit /b 1


:RUN_DIAN_INIT

echo Running:
echo   "%BASE_DIR%\Dian\init.bat"
echo.

call "%BASE_DIR%\Dian\init.bat"
set "INIT_RESULT=%errorlevel%"

goto INIT_FINISHED


:RUN_ROOT_INIT

echo Running:
echo   "%BASE_DIR%\init.bat"
echo.

call "%BASE_DIR%\init.bat"
set "INIT_RESULT=%errorlevel%"

goto INIT_FINISHED


:INIT_FINISHED

echo.

if not "%INIT_RESULT%"=="0" (
    echo [ERROR] init.bat returned error code %INIT_RESULT%.
    exit /b %INIT_RESULT%
)

echo ============================================================
echo Installation completed successfully.
echo ============================================================
echo.

exit /b 0
