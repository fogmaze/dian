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


rem ============================================================
rem Download settings
rem ============================================================

set "ZIP_URL=https://github.com/fogmaze/dian/releases/latest/download/dian.zip"

rem Download and extract to the current user's Desktop
set "BASE_DIR=%USERPROFILE%\Desktop"
set "ZIP_FILE=%BASE_DIR%\Dian.zip"
set "PART_FILE=%BASE_DIR%\Dian.zip.part"

rem Number of retries after the first attempt
set "DOWNLOAD_MAX_RETRIES=5"

rem Delay between retries, in seconds
set "DOWNLOAD_RETRY_DELAY=5"

set /a DOWNLOAD_MAX_ATTEMPTS=DOWNLOAD_MAX_RETRIES+1


rem ============================================================
rem Check required directories and commands
rem ============================================================

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


rem ============================================================
rem Remove files left by an older completed installation
rem ============================================================

if exist "%ZIP_FILE%" (
    del /q "%ZIP_FILE%" >nul 2>&1
)

rem Keep an existing .part file so that a previously interrupted
rem installation can also continue downloading.
rem
rem Delete the following file manually if you want to restart
rem the download completely:
rem   %PART_FILE%


rem ============================================================
rem Download with retry and resume support
rem ============================================================

echo.
echo [1/3] Downloading...

set /a DOWNLOAD_ATTEMPT=0


:DOWNLOAD_RETRY

set /a DOWNLOAD_ATTEMPT+=1

echo.
echo ------------------------------------------------------------
echo Download attempt %DOWNLOAD_ATTEMPT% of %DOWNLOAD_MAX_ATTEMPTS%
echo ------------------------------------------------------------
echo.

curl.exe -L ^
    --fail ^
    --show-error ^
    --connect-timeout 30 ^
    --speed-limit 1024 ^
    --speed-time 60 ^
    --continue-at - ^
    -o "%PART_FILE%" ^
    "%ZIP_URL%"

set "CURL_RESULT=%errorlevel%"

if "%CURL_RESULT%"=="0" goto DOWNLOAD_FINISHED


rem ============================================================
rem Download attempt failed
rem ============================================================

echo.
echo [WARNING] Download attempt %DOWNLOAD_ATTEMPT% failed.
echo curl.exe returned error code %CURL_RESULT%.


rem curl error 33 means the server did not accept resume requests.
rem Delete the partial file so the next attempt starts from zero.

if "%CURL_RESULT%"=="33" (
    echo.
    echo The server did not accept the resume request.
    echo The next attempt will restart the download from zero.

    if exist "%PART_FILE%" (
        del /q "%PART_FILE%" >nul 2>&1
    )
)


rem Stop after all attempts have been used.

if %DOWNLOAD_ATTEMPT% GEQ %DOWNLOAD_MAX_ATTEMPTS% goto DOWNLOAD_FAILED


echo.
echo Retrying in %DOWNLOAD_RETRY_DELAY% seconds...
echo The incomplete download will be resumed if possible.

timeout /t %DOWNLOAD_RETRY_DELAY% /nobreak >nul

goto DOWNLOAD_RETRY


rem ============================================================
rem Download completed
rem ============================================================

:DOWNLOAD_FINISHED

if not exist "%PART_FILE%" (
    echo.
    echo [ERROR] The downloaded file was not created:
    echo   "%PART_FILE%"
    exit /b 1
)

for %%A in ("%PART_FILE%") do set "DOWNLOADED_SIZE=%%~zA"

if "%DOWNLOADED_SIZE%"=="0" (
    echo.
    echo [ERROR] The downloaded file is empty:
    echo   "%PART_FILE%"

    del /q "%PART_FILE%" >nul 2>&1

    exit /b 1
)

move /y "%PART_FILE%" "%ZIP_FILE%" >nul 2>&1

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to rename the completed download.
    echo.
    echo Source:
    echo   "%PART_FILE%"
    echo.
    echo Destination:
    echo   "%ZIP_FILE%"
    exit /b 1
)

if not exist "%ZIP_FILE%" (
    echo.
    echo [ERROR] ZIP file was not created:
    echo   "%ZIP_FILE%"
    exit /b 1
)

echo.
echo Download completed successfully.
echo Downloaded size: %DOWNLOADED_SIZE% bytes


rem ============================================================
rem All download attempts failed
rem ============================================================

goto EXTRACT_ARCHIVE


:DOWNLOAD_FAILED

echo.
echo ============================================================
echo [ERROR] Download failed after %DOWNLOAD_MAX_ATTEMPTS% attempts.
echo ============================================================
echo.
echo URL:
echo   "%ZIP_URL%"
echo.
echo Partial download:
echo   "%PART_FILE%"
echo.
echo The partial file has been kept.
echo Run this installer again to continue the download.
echo.

exit /b %CURL_RESULT%


rem ============================================================
rem Extract archive
rem ============================================================

:EXTRACT_ARCHIVE

echo.
echo [2/3] Extracting...

tar.exe -xf "%ZIP_FILE%" -C "%BASE_DIR%"

if errorlevel 1 (
    echo.
    echo [ERROR] Extraction failed.
    echo.
    echo ZIP file:
    echo   "%ZIP_FILE%"
    echo.
    echo The downloaded ZIP may be incomplete or damaged.
    echo Delete the following files and run the installer again:
    echo   "%ZIP_FILE%"
    echo   "%PART_FILE%"
    exit /b 1
)

del /q "%ZIP_FILE%" >nul 2>&1


rem ============================================================
rem Find and run init.bat
rem ============================================================

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
