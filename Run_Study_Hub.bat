@echo off
title Study Hub - Professional Flutter Launcher
color 0B
cls

echo ========================================================
echo               STUDY HUB - FLUTTER LAUNCHER
echo ========================================================
echo.
echo  [1] Launch as Windows Desktop App (flutter run -d windows)
echo  [2] Launch in Google Chrome Web (flutter run -d chrome)
echo  [3] Run Pre-built Fast Web App (Instant local server)
echo  [4] Build Android APK (flutter build apk)
echo  [5] Exit
echo.
echo ========================================================
set /p choice="Select an option (1-5): "

if "%choice%"=="1" goto run_windows
if "%choice%"=="2" goto run_chrome
if "%choice%"=="3" goto run_prebuilt
if "%choice%"=="4" goto build_apk
if "%choice%"=="5" goto end

echo Invalid option selected.
pause
goto end

:run_windows
echo.
echo Starting Study Hub for Windows Desktop...
flutter run -d windows
pause
goto end

:run_chrome
echo.
echo Starting Study Hub in Chrome...
flutter run -d chrome
pause
goto end

:run_prebuilt
echo.
echo Starting local web server on http://localhost:5500 ...
start "" "http://localhost:5500"
python -m http.server 5500 --directory build/web
pause
goto end

:build_apk
echo.
echo Building Release APK for Android...
flutter build apk --release
echo.
echo APK built in: build\app\outputs\flutter-apk\app-release.apk
pause
goto end

:end
exit
