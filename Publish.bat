@echo off
setlocal EnableDelayedExpansion

REM Lightweight publish script without VS tooling.
set "root=%~dp0"
set "outputDirectory=%root%Publish"

REM Clean output to avoid stale test/tooling assemblies.
if exist "%outputDirectory%" rmdir /s /q "%outputDirectory%"
mkdir "%outputDirectory%"

echo [1/4] Build with dotnet (RePKG only)...
dotnet build "%root%RePKG\RePKG.csproj" -c Release -p:OutputPath="%outputDirectory%"
if errorlevel 1 goto :error

echo [2/4] Locate ilrepack...
set "ilrepack="
for %%I in ("%USERPROFILE%\.dotnet\tools\ilrepack.exe" "ilrepack.exe") do (
    if exist %%~I set "ilrepack=%%~I"
)
if not defined ilrepack (
    echo ilrepack not found. Ensure ilrepack.exe is in PATH or at "%USERPROFILE%\.dotnet\tools\ilrepack.exe".
    goto :error
)

echo [3/4] Merge assemblies...
move /Y "%outputDirectory%\RePKG.exe" "%outputDirectory%\input.exe" >nul
"%ilrepack%" /out:"%outputDirectory%\RePKG.exe" /wildcards /parallel "%outputDirectory%\input.exe" "%outputDirectory%\*.dll"
if errorlevel 1 goto :error

echo [3.5/4] Clean intermediate files...
del /q "%outputDirectory%\input.exe" 2>nul
del /q "%outputDirectory%\*.dll" 2>nul
del /q "%outputDirectory%\*.pdb" 2>nul
del /q "%outputDirectory%\*.config" 2>nul
del /q "%outputDirectory%\*.json" 2>nul

echo [4/4] Create zip...
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

echo Done. Output: %outputDirectory%\RePKG.exe and RePKG.zip
goto :eof

:error
echo Publish failed. See messages above.
exit /b 1
