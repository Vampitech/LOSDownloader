@echo off
chcp 65001
color 1f
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"

where /q tar
if %errorlevel% neq 0 (
    echo La utilidad de descompresión de archivos no está presente.
    echo Este script solo es funcional desde Windows 10 1809 en adelante.
    echo por favor, reporte este error a https://discord.vampitech.net
    pause
    goto end
)


:menu
cls
:::
:::  __     __                    _ _            _     
:::  \ \   / /_ _ _ __ ___  _ __ (_) |_ ___  ___| |__  
:::   \ \ / / _` | '_ ` _ \| '_ \| | __/ _ \/ __| '_ \ 
:::    \ V / (_| | | | | | | |_) | | ||  __/ (__| | | |
:::     \_/ \__,_|_| |_| |_| .__/|_|\__\___|\___|_| |_|
:::                        |_|                         
for /f "delims=: tokens=*" %%A in ('findstr /b ::: "%~f0"') do @echo(%%A
echo ____________________________________________________
echo.
echo      Lineage OS Downloader Script by Vampitech
echo      Soporte en https://discord.vampitech.net
echo ____________________________________________________
echo.

echo 1. Android Normal (nx_tab)
echo 2. Android TV (nx)
echo 3. Salir
echo.
choice /c 123 /n /m "Ingresa una opcion: "

if %errorlevel% == 1 (
    set LOS_EP="https://download.lineageos.org/api/v2/devices/nx_tab/builds"
    goto bajarArchivos
) else if %errorlevel% == 2 (
    set LOS_EP="https://download.lineageos.org/api/v2/devices/nx/builds"
    goto bajarArchivos
) else if %errorlevel% == 3 (
    exit
)

:bajarArchivos
mkdir "%SCRIPT_DIR%out\fase1"
mkdir "%SCRIPT_DIR%out\fase2\switchroot\android"
mkdir "%SCRIPT_DIR%out\fase2\switchroot\install"
curl -s %LOS_EP% > assets.json
jq -r ".[0].files[].filename" assets.json > archivos.txt

echo DESCARGANDO ARCHIVOS DE LINEAGE OS... ESPERA
for /f "delims=" %%a in ('jq -r ".[0].files[].url" assets.json') do (
    wget -P "%SCRIPT_DIR%out\fase2" %%a
)
wget -qP "%SCRIPT_DIR%out\fase2\switchroot\android" https://wiki.lineageos.org/images/device_specific/nx/bootlogo_android.bmp
wget -qP "%SCRIPT_DIR%out\fase2\switchroot\android" https://wiki.lineageos.org/images/device_specific/nx/icon_android_hue.bmp

echo COMPROBANDO ARCHIVOS
for /f "delims=" %%a in (archivos.txt) do (
    set "archivo=%%a"

    if exist "%SCRIPT_DIR%out\fase2\!archivo!" (
        echo !archivo! Comprobacion OK!.
    ) else (
        echo !archivo! NO se descargo.
        echo.
        goto errEnd
    )
)

echo DESCARGANDO Gapps (Google Play)
wget -qO- "https://api.github.com/repos/MindTheGapps/15.0.0-arm64/releases/latest" | jq -r ".assets[0].browser_download_url" | wget -P "%SCRIPT_DIR%out\fase2" -i -

echo DESCARGANDO Hekate
for /f "delims=" %%a in ('wget -qO- "https://api.github.com/repos/ctcaer/hekate/releases/latest" ^| jq -r ".assets[0].name"') do set "hekafile=%%a"
wget -qO- "https://api.github.com/repos/ctcaer/hekate/releases/latest" | jq -r ".assets[0].browser_download_url" | wget -qP "%SCRIPT_DIR%out\fase1" -i -
tar -xf "%SCRIPT_DIR%out\fase1\!hekafile!" -C "%SCRIPT_DIR%out\fase1"
del "%SCRIPT_DIR%out\fase1\!hekafile!"
ren "%SCRIPT_DIR%out\fase1\*.bin" payload.bin

rem ATMOS
wget -qO- "https://api.github.com/repos/vampitech/atmovainilla/releases/latest" | jq -r ".assets[0].browser_download_url" | wget -qP "%SCRIPT_DIR%out\fase1" -i -
tar -xf "%SCRIPT_DIR%out\fase1\atmos_vanilla.zip" -C "%SCRIPT_DIR%out\fase1"
del "%SCRIPT_DIR%out\fase1\atmos_vanilla.zip"

echo MOVIENDO Y ORGANIZANDO ARCHIVOS...
for %%i in ("%SCRIPT_DIR%out\fase2\boot.img" "%SCRIPT_DIR%out\fase2\recovery.img" "%SCRIPT_DIR%out\fase2\nx-plat.dtimg") do (move %%i "%SCRIPT_DIR%out\fase2\switchroot\install")
for %%i in ("%SCRIPT_DIR%out\fase2\bl31.bin" "%SCRIPT_DIR%out\fase2\bl33.bin" "%SCRIPT_DIR%out\fase2\boot.scr") do (move %%i "%SCRIPT_DIR%out\fase2\switchroot\android")
del "%SCRIPT_DIR%out\fase2\super_empty.img"
del assets.json
del archivos.txt
rem cls
echo.
echo Los archivos de Android y GApps se han descargado y preparado correctamente.
echo.
echo.
echo ----------------------------------------------------------------------
echo                           A T E N C I O N
echo ----------------------------------------------------------------------
echo.
echo Este script viene con un pack básico de CFW Atmosphere con Sigpatches
echo se sugiere integrar un pack todo en uno que tiene un set de herramientas
echo preparadas para sacar todo el potencial tanto de tu emuNAND como de tu sistema
echo Android. Deseas integrar NeXT AIO (Pack oficial de Vampitech)?
echo.
echo 1. Sí (Recomendado)
echo 2. Mantener Atmosphere básico
echo.
choice /c 12 /n /m "Ingresa una opcion: "
if %errorlevel% == 1 goto bajarNext
if %errorlevel% == 2 goto NoNeXTend
)


:bajarNeXT
echo Descargando e integrando NeXT
wget -qO- "https://codeberg.org/api/v1/repos/vampitech/NeXT/releases/latest" | jq -r ".assets[0].browser_download_url" | wget -P "%SCRIPT_DIR%out\fase2" -i -
tar -xf "%SCRIPT_DIR%out\fase2\NeXT.zip" -C "%SCRIPT_DIR%out\fase2"
del "%SCRIPT_DIR%out\fase2\NeXT.zip"
rmdir /s /q "%SCRIPT_DIR%out\fase2\PC"
xcopy "%SCRIPT_DIR%out\fase2\SD\*" "%SCRIPT_DIR%out\fase2\" /E /H /Y
rmdir /s /q "%SCRIPT_DIR%out\fase2\SD"
echo NeXT ha sido integrado correctamente
pause
goto end

:NoNeXTend
echo No se integrara NeXT y se usará el pack basico de Atmosphere
echo Se escribirá la entrada de Inicio de Android para Hekate
echo Escribiendo configuracion de Android...
(
echo [Android]
echo l4t=1
echo boot_prefixes=switchroot/android/
echo id=SWANDR
echo icon=switchroot/android/icon_android_hue.bmp
echo logopath=switchroot/android/bootlogo_android.bmp
echo r2p_action=normal
echo ;usb3_enable=0
echo {}
) > out\fase1\bootloader\ini\android.ini
goto end

:end
del /q .wget-hsts
echo ----------------------------------------------------------------------------------
echo. 
echo        Los archivos han sido descargados y preparados satisfactoriamente
echo             Se abrirá una ventana con los archivos resultantes.
echo    NOTA: Si no se abre, busca la carpeta OUT desde donde se ejecutó el script
echo. 
echo               La carpeta FASE1 debe copiarse con la microSD vacía
echo        a fin de crear las particiones de emuNAND y Android desde Hekate
echo                            en la consola Switch.
echo.
echo          La carpeta FASE2 debe copiarse despues de crear las particiones
echo         NOTA: NO ES NECESARIO BORRAR NADA DE LA SD, SOLO COPIAR LOS ARCHIVOS
echo      Y SI EL SISTEMA PREGUNTA SI DESEAS SOBREESCRIBIR ARCHIVOS DAR CLICK EN SI
echo. 
echo              En caso de errores, por favor no dudes en reportarlo en
echo                        https://discord.vampitech.net
echo.
echo -----------------------------------------------------------------------------------
echo.
pause
start "" out
color 0f
exit

:errEnd
echo Error al descargar archivos.
echo Verifica tu conexion a internet y vuelve a intentarlo.
echo Si sigue sin funcionar, reporta el fallo a https://discord.vampitech.net
color 0f
echo.
exit
