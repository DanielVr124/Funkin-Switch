@echo off
setlocal EnableExtensions
pushd "%~dp0\..\.."
if errorlevel 1 goto :failed_to_enter

set "BUILD_EXIT=1"
set "HMM_BACKUP=%TEMP%\fnf-hmm-desktop-%RANDOM%.json"

echo.
echo ============================================================
echo  Friday Night Funkin' - Nintendo Switch Release Build
echo ============================================================
echo.

where haxelib >nul 2>nul
if errorlevel 1 (
  echo ERROR: Haxelib is not on PATH.
  goto :finish
)
where python >nul 2>nul
if errorlevel 1 (
  echo ERROR: Python is required for the pinned Switch dependency patch.
  goto :finish
)
if not defined DEVKITPRO (
  echo ERROR: DEVKITPRO is not set. Install DevKitPro and DevKitA64.
  goto :finish
)
if not exist "%DEVKITPRO%\devkitA64\bin\aarch64-none-elf-g++.exe" (
  echo ERROR: DevKitA64 compiler was not found under "%DEVKITPRO%".
  goto :finish
)
if not exist "%DEVKITPRO%\libnx\include\switch.h" (
  echo ERROR: libnx headers were not found under "%DEVKITPRO%".
  goto :finish
)
if not exist "hmm-switch.json" (
  echo ERROR: hmm-switch.json is missing.
  goto :finish
)

copy /y "hmm.json" "%HMM_BACKUP%" >nul
if errorlevel 1 (
  echo ERROR: Could not back up the normal desktop dependency manifest.
  goto :finish
)

echo [1/5] Selecting Switch-only Haxe dependencies...
copy /y "hmm-switch.json" "hmm.json" >nul
if errorlevel 1 (
  echo ERROR: Could not select hmm-switch.json.
  goto :restore
)

echo [2/5] Installing Switch dependencies...
haxelib run hmm install -q
if errorlevel 1 (
  echo ERROR: HMM dependency installation failed.
  goto :restore
)

echo [3/5] Applying pinned Switch compatibility patches...
python tools\patch-switch-dependencies.py
if errorlevel 1 (
  echo ERROR: Switch dependency compatibility patch failed.
  goto :restore
)

echo Compiling HXCPP build tools...
pushd ".haxelib\hxcpp\git\tools\hxcpp"
if errorlevel 1 (
  echo ERROR: HXCPP tools folder is missing.
  goto :restore
)
haxe compile.hxml
if errorlevel 1 (
  popd
  echo ERROR: HXCPP build tools failed.
  goto :restore
)
popd

echo.
echo [4/6] Rebuilding Lime for Windows (host tools)...
haxelib run lime rebuild windows -64
if errorlevel 1 (
  echo ERROR: Lime Windows host-runtime rebuild failed.
  goto :restore
)

echo.
echo [5/6] Rebuilding Lime for Nintendo Switch...
haxelib run lime rebuild switch
if errorlevel 1 (
  echo ERROR: Lime Switch rebuild failed.
  goto :restore
)

echo.
echo [6/6] Building the release NRO...
haxelib run lime build switch -v -release -DGITHUB_BUILD
if errorlevel 1 (
  echo ERROR: Switch release compilation failed.
  goto :restore
)

if not exist "export\release\switch\bin\Funkin.nro" (
  echo ERROR: Build returned successfully but Funkin.nro was not found.
  goto :restore
)

set "BUILD_EXIT=0"
echo.
echo SWITCH RELEASE BUILD SUCCEEDED:
echo export\release\switch\bin\Funkin.nro

:restore
if exist "%HMM_BACKUP%" (
  copy /y "%HMM_BACKUP%" "hmm.json" >nul
  del "%HMM_BACKUP%" >nul 2>nul
  echo.
  echo Restored the standard desktop hmm.json.
)

:finish
popd
echo.
if "%BUILD_EXIT%"=="0" (
  echo Switch release build complete.
) else (
  echo Switch release build did not complete.
)
pause
exit /b %BUILD_EXIT%

:failed_to_enter
echo ERROR: Could not enter the repository root.
pause
exit /b 1
