@echo off
title Programa para activar compatibilidad de cajas By LPN

echo ================================================
echo Programa para activar compatibilidad de cajas
echo                   By LPN
echo ================================================
echo.

:: Verificar ejecución con permisos de administrador
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo Por favor ejecuta este script como Administrador.
    pause
    exit /b 1
)

echo Modificando registro para aumentar limite WebDAV...

reg add "HKLM\SYSTEM\CurrentControlSet\Services\WebClient\Parameters" /v FileSizeLimitInBytes /t REG_DWORD /d 4294967295 /f

echo Reiniciando servicio WebClient...
sc stop WebClient
timeout /t 5 /nobreak >nul
sc start WebClient

echo Descargando SPICE Guest Tools...
powershell -Command "Invoke-WebRequest -Uri https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe -OutFile $env:TEMP\spice-guest-tools-latest.exe"

echo Instalando SPICE Guest Tools...
start /wait "" "%TEMP%\spice-guest-tools-latest.exe" /SILENT

echo Descargando SPICE WebDAV daemon...
powershell -Command "Invoke-WebRequest -Uri https://www.spice-space.org/download/windows/spice-webdavd/spice-webdavd-x64-latest.msi -OutFile $env:TEMP\spice-webdavd-latest.msi"

echo Instalando SPICE WebDAV daemon...
msiexec /i "%TEMP%\spice-webdavd-latest.msi" /quiet /norestart

echo Instalacion finalizada. Por favor reinicia la PC para aplicar todos los cambios.
pause
