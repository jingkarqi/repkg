@echo off
setlocal EnableDelayedExpansion

REM Lightweight publish script without VS tooling.
set "root=%~dp0"
set "outputDirectory=%root%Publish"
set "cliOutput=%outputDirectory%\cli"
set "guiOutput=%outputDirectory%\gui"
set "buildGui=1"

REM Allow CLI-only publish for compatibility:
REM   Publish.bat nogui
REM   set REPKG_NO_GUI=1 && Publish.bat
if /I "%~1"=="nogui" set "buildGui=0"
if /I "%~1"=="cli" set "buildGui=0"
if /I "%~1"=="cli-only" set "buildGui=0"
if /I "%~1"=="--no-gui" set "buildGui=0"
if /I "%REPKG_NO_GUI%"=="1" set "buildGui=0"
if /I "%REPKG_NO_GUI%"=="true" set "buildGui=0"

set "totalSteps=4"
if "%buildGui%"=="1" set "totalSteps=5"

REM Clean output to avoid stale test/tooling assemblies.
if exist "%outputDirectory%" rmdir /s /q "%outputDirectory%"
mkdir "%outputDirectory%"
mkdir "%cliOutput%"
if "%buildGui%"=="1" mkdir "%guiOutput%"

echo [1/%totalSteps%] Build CLI with dotnet...
dotnet build "%root%RePKG\RePKG.csproj" -c Release -p:OutputPath="%cliOutput%\\"
if errorlevel 1 goto :error

echo [2/%totalSteps%] Locate ilrepack...
set "ilrepack="
for %%I in ("%USERPROFILE%\.dotnet\tools\ilrepack.exe" "ilrepack.exe") do (
    if exist %%~I set "ilrepack=%%~I"
)
if not defined ilrepack (
    echo ilrepack not found. Ensure ilrepack.exe is in PATH or at "%USERPROFILE%\.dotnet\tools\ilrepack.exe".
    goto :error
)

echo [3/%totalSteps%] Merge CLI assemblies...
move /Y "%cliOutput%\RePKG.exe" "%cliOutput%\input.exe" >nul
"%ilrepack%" /out:"%outputDirectory%\RePKG.exe" /wildcards /parallel "%cliOutput%\input.exe" "%cliOutput%\*.dll"
if errorlevel 1 goto :error

echo [3.5/%totalSteps%] Clean CLI intermediates...
del /q "%cliOutput%\input.exe" 2>nul
del /q "%cliOutput%\*.dll" 2>nul
del /q "%cliOutput%\*.pdb" 2>nul
del /q "%cliOutput%\*.config" 2>nul
del /q "%cliOutput%\*.json" 2>nul
rmdir /s /q "%cliOutput%" 2>nul

if "%buildGui%"=="1" (
    echo [4/%totalSteps%] Build GUI with dotnet...
    dotnet build "%root%RePKG.Gui\RePKG.Gui.csproj" -c Release -p:OutputPath="%guiOutput%\\"
    if errorlevel 1 (
        echo GUI build failed. Continuing with CLI-only publish.
        set "buildGui=0"
    ) else (
        echo [4.5/%totalSteps%] Copy GUI binaries...
        for %%F in ("%guiOutput%\*") do (
            if not exist "%%F\\NUL" (
                if /I not "%%~nxF"=="RePKG.exe" copy /Y "%%F" "%outputDirectory%\" >nul
            )
        )
        del /q "%outputDirectory%\*.pdb" 2>nul
    )
    rmdir /s /q "%guiOutput%" 2>nul
)

echo [%totalSteps%/%totalSteps%] Create zip...
if exist "%outputDirectory%\RePKG.zip" del "%outputDirectory%\RePKG.zip"
REM Prefer 7z if available; otherwise fall back to PowerShell Compress-Archive.
where 7z >nul 2>&1
if not errorlevel 1 (
    pushd "%outputDirectory%"
    7z a -tzip RePKG.zip * >nul
    popd
) else (
    powershell -NoLogo -NoProfile -Command "Compress-Archive -Path '%outputDirectory%\*' -DestinationPath '%outputDirectory%\RePKG.zip' -Force"
)

if "%buildGui%"=="1" (
    echo Done. Output: %outputDirectory%\RePKG.exe, %outputDirectory%\RePKG.Gui.exe and RePKG.zip
) else (
    echo Done. Output: %outputDirectory%\RePKG.exe and RePKG.zip
)
goto :eof

:error
echo Publish failed. See messages above.
exit /b 1
