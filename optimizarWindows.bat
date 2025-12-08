@echo off
chcp 65001 >nul

echo =====================================================
echo   OPTIMIZACIÓN DE WINDOWS 10 PARA RENDIMIENTO (GAMING)
echo   Debe ejecutarse como ADMINISTRADOR
echo =====================================================
echo.

:: Comprobar si se está ejecutando como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script debe ejecutarse como Administrador.
    echo Clic derecho sobre el .bat y elige "Ejecutar como administrador".
    pause
    exit /b 1
)

echo [OK] Ejecución con privilegios de administrador.
echo.

:: 1. ACTIVAR PLAN DE ENERGÍA DE ALTO RENDIMIENTO
echo [1/7] Activando plan de energia de ALTO RENDIMIENTO...
powercfg -setactive SCHEME_MAX
echo     - Plan de energia ajustado a Alto rendimiento.
echo.

:: 2. DESHABILITAR SERVICIOS PESADOS (SysMain, Windows Search, Telemetria)
echo [2/7] Deshabilitando servicios que consumen recursos...

:: SysMain (antes Superfetch)
sc stop "SysMain" >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1
echo     - SysMain deshabilitado.

:: Windows Search (Indexación)
sc stop "WSearch" >nul 2>&1
sc config "WSearch" start= disabled >nul 2>&1
echo     - Windows Search deshabilitado (indexación de disco).

:: Telemetria (Connected User Experiences and Telemetry)
sc stop "DiagTrack" >nul 2>&1
sc config "DiagTrack" start= disabled >nul 2>&1
echo     - DiagTrack (telemetria) deshabilitado.

:: dmwappushservice (servicio relacionado con telemetria)
sc stop "dmwappushservice" >nul 2>&1
sc config "dmwappushservice" start= disabled >nul 2>&1
echo     - dmwappushservice deshabilitado.
echo.

:: 3. DESACTIVAR GAME DVR Y GAME BAR
echo [3/7] Desactivando Game DVR y Game Bar...

:: Game DVR via directiva
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul

:: Game Bar en el usuario actual
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v ShowStartupPanel /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v GameBarEnabled /t REG_DWORD /d 0 /f >nul

echo     - Game DVR y Game Bar desactivados (evita capturas y overlays innecesarios).
echo.

:: 4. AJUSTAR EFECTOS VISUALES A "MEJOR RENDIMIENTO"
echo [4/7] Ajustando efectos visuales para MEJOR RENDIMIENTO...

:: 0 = dejar que Windows decida
:: 1 = mejor apariencia
:: 2 = mejor rendimiento
:: 3 = personalizado
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul

echo     - Efectos visuales configurados para mejor rendimiento.
echo.

:: 5. DESINSTALAR ONEDRIVE (SI EXISTE)
echo [5/7] Intentando desinstalar OneDrive...

if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
    "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall
    echo     - OneDrive (64 bits) desinstalado (si estaba presente).
) else if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
    "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall
    echo     - OneDrive (32 bits) desinstalado (si estaba presente).
) else (
    echo     - OneDrive no parece estar instalado o ya fue eliminado.
)
echo.

:: 6. DESACTIVAR APLICACIONES EN SEGUNDO PLANO (PARCIAL)
echo [6/7] Desactivando algunas aplicaciones en segundo plano (via registro)...

:: Esto desactiva "aplicaciones en segundo plano" a nivel usuario actual
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 0 /f >nul

echo     - Apps en segundo plano limitadas para el usuario actual.
echo.

:: 7. MENSAJE FINAL Y RECOMENDACIÓN DE REINICIO
echo [7/7] OPTIMIZACIÓN COMPLETADA.
echo.
echo Es recomendable REINICIAR Windows para que todos los cambios se apliquen correctamente.
echo.

pause
exit /b 0
