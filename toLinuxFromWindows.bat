@echo off
setlocal enabledelayedexpansion
title Instalador profesional VITURE ULTRA y Cajas - By LPN

echo ============================================================
echo  Instalador para usar VITURE Luma Ultra / XR en Windows
echo  + Activación de Compatibilidad (Cajas)
echo                         By LPN
echo ============================================================
echo.

::-------------------------------
:: 1. Comprobar permisos de administrador
::-------------------------------
echo [1/9] Comprobando permisos de Administrador...
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Por favor ejecuta este script como Administrador.
    echo         Click derecho sobre el .bat -> "Ejecutar como administrador".
    pause
    exit /b 1
)
echo [OK] Permisos de Administrador detectados.
echo.

::-------------------------------
:: 2. Activar compatibilidad de cajas (Modificación WebDAV)
::-------------------------------
echo [2/9] Activando compatibilidad de cajas (Modificación WebDAV)...
echo     Esto aumenta el limite de tamaño de archivos en conexiones WebDAV.
echo.

set "REG_PATH=HKLM\SYSTEM\CurrentControlSet\Services\WebClient\Parameters"
set "MAX_SIZE=4294967295" 

reg add "%REG_PATH%" /v FileSizeLimitInBytes /t REG_DWORD /d %MAX_SIZE% /f >nul 2>&1

if errorlevel 1 (
    echo [ERROR] No se pudo modificar el registro de WebDAV. La compatibilidad puede fallar.
) else (
    echo [OK] Registro de WebDAV modificado correctamente.
    echo Reiniciando servicio WebClient...

    net stop webclient >nul 2>&1
    if errorlevel 1 (
        echo [ADVERTENCIA] No se pudo detener el servicio WebClient.
        echo                Es posible que debas reiniciar Windows manualmente.
    ) else (
        net start webclient >nul 2>&1
        if errorlevel 1 (
            echo [ADVERTENCIA] No se pudo iniciar de nuevo el servicio WebClient.
            echo                Es posible que debas reiniciar Windows manualmente.
        ) else (
            echo [OK] Servicio WebClient reiniciado correctamente.
        )
    )
)
echo.

::-------------------------------
:: 3. Comprobar arquitectura del sistema
::-------------------------------
echo [3/9] Comprobando arquitectura del sistema...
if /i not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo [ADVERTENCIA] Este script esta pensado para Windows de 64 bits.
    echo               VITURE solo soporta oficialmente x64 en PC.
    echo.
) else (
    echo [OK] Arquitectura de 64 bits detectada.
)
echo.

::-------------------------------
:: 4. Definir URLs oficiales y rutas de descarga
::-------------------------------
set "SPACEWALKER_URL=https://static.viture.dev/external-file/Windows/SpaceWalker-Installer.exe"
set "IMMERSIVE3D_URL=https://static.viture.dev/external-file/Windows/Immersive3D-Installer.exe"

set "DOWNLOAD_DIR=%TEMP%\VitureSetup"

if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%" 2>nul
    if errorlevel 1 (
        echo [ERROR] No se pudo crear la carpeta de trabajo en:
        echo         %DOWNLOAD_DIR%
        pause
        exit /b 1
    )
)

echo [4/9] Carpeta de trabajo: %DOWNLOAD_DIR%
echo.

::-------------------------------
:: 5. Comprobar que PowerShell esta disponible
::-------------------------------
echo [5/9] Comprobando disponibilidad de PowerShell...
where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell no esta disponible en este sistema.
    echo         No se pueden descargar automaticamente los instaladores.
    pause
    exit /b 1
)
echo [OK] PowerShell disponible.
echo.

::-------------------------------
:: 6. Descargar SpaceWalker para Windows
::-------------------------------
echo [6/9] Descargando SpaceWalker para Windows...
powershell -NoLogo -NoProfile -Command ^
 "Invoke-WebRequest -UseBasicParsing -Uri '%SPACEWALKER_URL%' -OutFile '%DOWNLOAD_DIR%\SpaceWalker-Installer.exe'" 2>nul

if not exist "%DOWNLOAD_DIR%\SpaceWalker-Installer.exe" (
    echo [ERROR] No se pudo descargar SpaceWalker-Installer.exe
    echo         Revisa tu conexion a Internet o la URL de descarga.
    pause
    exit /b 1
)

echo [OK] SpaceWalker descargado correctamente.
echo.

::-------------------------------
:: 7. Descargar Immersive 3D para Windows
::-------------------------------
echo [7/9] Descargando Immersive 3D para Windows...
powershell -NoLogo -NoProfile -Command ^
 "Invoke-WebRequest -UseBasicParsing -Uri '%IMMERSIVE3D_URL%' -OutFile '%DOWNLOAD_DIR%\Immersive3D-Installer.exe'" 2>nul

if not exist "%DOWNLOAD_DIR%\Immersive3D-Installer.exe" (
    echo [ADVERTENCIA] No se pudo descargar Immersive3D-Installer.exe
    echo              Continuare solo con SpaceWalker (lo esencial para usar las gafas).
    echo.
) else (
    echo [OK] Immersive 3D descargado correctamente.
    echo.
)

::-------------------------------
:: 8. Instalar SpaceWalker y Immersive 3D
::-------------------------------
echo [8/9] Iniciando instalacion de SpaceWalker y Immersive 3D...
echo     Sigue los asistentes de instalacion que se abriran a continuacion.
echo.

:: Instalar SpaceWalker
echo [8.1/8.2] Instalando SpaceWalker...
start "" /wait "%DOWNLOAD_DIR%\SpaceWalker-Installer.exe"

if errorlevel 1 (
    echo [ADVERTENCIA] El instalador de SpaceWalker devolvio un codigo distinto de 0.
    echo              Si SpaceWalker no esta instalado, ejecutalo manualmente:
    echo              "%DOWNLOAD_DIR%\SpaceWalker-Installer.exe"
) else (
    echo [OK] SpaceWalker instalado (o el instalador se cerro sin errores conocidos).
)
echo.

:: Instalar Immersive 3D (Opcional)
if exist "%DOWNLOAD_DIR%\Immersive3D-Installer.exe" (
    echo [8.2/8.2] Instalando Immersive 3D...
    start "" /wait "%DOWNLOAD_DIR%\Immersive3D-Installer.exe"

    if errorlevel 1 (
        echo [ADVERTENCIA] El instalador de Immersive 3D devolvio un codigo distinto de 0.
        echo              Si lo necesitas, ejecutalo manualmente:
        echo              "%DOWNLOAD_DIR%\Immersive3D-Installer.exe"
    ) else (
        echo [OK] Immersive 3D instalado (o el instalador se cerro sin errores conocidos).
    )
    echo.
) else (
    echo [INFO] Immersive 3D no se descargo/instalo. Solo SpaceWalker.
    echo.
)

::-------------------------------
:: Limpieza opcional de instaladores
::-------------------------------
rem echo [INFO] Limpiando instaladores temporales...
rem del /q "%DOWNLOAD_DIR%\SpaceWalker-Installer.exe" 2>nul
rem del /q "%DOWNLOAD_DIR%\Immersive3D-Installer.exe" 2>nul

::-------------------------------
:: 9. Finalizacion y Pasos Siguientes
::-------------------------------
echo [9/9] Abriendo pagina oficial de actualizacion de firmware...
start "" "https://www.viture.com/firmware/update"

echo.
echo ============================================================
echo  INSTALACION Y CONFIGURACION COMPLETADA
echo  Ahora deberias tener:
echo    - Configuracion de Compatibilidad (WebDAV) aplicada.
echo    - SpaceWalker y (Opcional) Immersive 3D instalados.
echo
echo  Siguientes pasos recomendados:
echo    1) IMPORTANTE: Actualiza el firmware de tus VITURE desde la pagina web abierta.
echo    2) Conecta las gafas a un puerto USB-C con DP Alt Mode.
echo    3) Verifica la compatibilidad de las "cajas" si es tu caso.
echo ============================================================
echo.

goto :fin

:fin
echo Pulsa una tecla para cerrar esta ventana...
pause >nul
endlocal
exit /b 0
