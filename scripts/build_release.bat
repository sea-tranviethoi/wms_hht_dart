@echo off
:: ─────────────────────────────────────────────────────────────────────────────
:: build_release.bat
:: Full release build pipeline for fbt_hht
::
:: Usage:
::   scripts\build_release.bat              (build without version bump)
::   scripts\build_release.bat --bump       (bump build number then build)
::   scripts\build_release.bat --bump-patch (bump patch version then build)
::
:: Output: build\app\outputs\flutter-apk\app-release.apk
::         Also copied to:  dist\fbt_hht_v<version>.apk
:: ─────────────────────────────────────────────────────────────────────────────

setlocal enabledelayedexpansion
cd /d "%~dp0.."

:: ── Environment paths ─────────────────────────────────────────
set FLUTTER_SDK=D:\OneDrive\Documents\flutter
set ANDROID_HOME=C:\Users\tranh\AppData\Local\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%
set PATH=%FLUTTER_SDK%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools;%PATH%

echo.
echo ============================================================
echo  FBT HHT — Release Build
echo ============================================================

:: ── Check flutter is on PATH ───────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] flutter not found on PATH. Add Flutter SDK bin to PATH.
    exit /b 1
)

:: ── Optional version bump ──────────────────────────────────────
if "%1"=="--bump" (
    echo [1/5] Bumping build number...
    powershell -ExecutionPolicy Bypass -File scripts\bump_version.ps1
    if errorlevel 1 exit /b 1
) else if "%1"=="--bump-patch" (
    echo [1/5] Bumping patch version...
    powershell -ExecutionPolicy Bypass -File scripts\bump_version.ps1 -patch
    if errorlevel 1 exit /b 1
) else (
    echo [1/5] Skipping version bump (pass --bump to auto-increment)
)

:: ── Read current version ───────────────────────────────────────
for /f "tokens=2 delims= " %%v in ('findstr /r "^version:" pubspec.yaml') do set VERSION=%%v
echo     Version: %VERSION%

:: ── Clean ─────────────────────────────────────────────────────
echo [2/5] Cleaning previous build artifacts...
call flutter clean
if errorlevel 1 ( echo [ERROR] flutter clean failed & exit /b 1 )

:: ── Dependencies ──────────────────────────────────────────────
echo [3/5] Fetching dependencies...
call flutter pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed & exit /b 1 )

:: ── Build APK ─────────────────────────────────────────────────
echo [4/5] Building release APK...
call flutter build apk --release --obfuscate --split-debug-info=build\debug_symbols
if errorlevel 1 ( echo [ERROR] flutter build apk failed & exit /b 1 )

:: ── Copy to dist/ ─────────────────────────────────────────────
echo [5/5] Copying APK to dist\...
if not exist dist mkdir dist

set APK_SRC=build\app\outputs\flutter-apk\app-release.apk
set APK_DST=dist\fbt_hht_v%VERSION%.apk

copy /Y "%APK_SRC%" "%APK_DST%"
if errorlevel 1 ( echo [WARN] Could not copy APK to dist\ & goto :done )

echo.
echo ============================================================
echo  BUILD SUCCESSFUL
echo  APK : %APK_DST%
echo  Size:
for %%F in ("%APK_DST%") do echo         %%~zF bytes
echo ============================================================

:done
endlocal
