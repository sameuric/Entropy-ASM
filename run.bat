REM 
REM     RUN.BAT (v1.0)
REM     -----------------------------------------------------------
REM 
REM     Small Batch script that runs several commands used to build
REM     and assemble the assembly code. This script also provides
REM     basic error management and clean program output.
REM 
REM     Script written for learning purposes only.
REM     © 2025 Sacha Meurice

@echo off & cls



REM  Script parameters
REM  ---------------------------------------------
REM  wd         Default working directory
REM  pName      Projet's cool name
REM  keepLog    Set it to 1 to keep build.log file
REM  masmLoc    MASM32 files location
REM  mode       Assembly building mode

set wd="%cd%"
set pName=code
set keepLog=0
set masmLoc=C:\masm32
set mode=windows




REM ---------------------------------------------------------------
REM               DO NOT EDIT BELOW THIS POINT UNLESS
REM                   YOU KNOW WHAT YOU ARE DOING
REM ---------------------------------------------------------------



REM Check if MASM32 files exist
if not exist "%masmLoc%" (
    echo ERROR: Could not find %masmLoc% directory.
    goto :ERROR1
)

if not exist "%masmLoc%\bin" (
    echo ERROR: Could not find %masmLoc%\bin directory.
    goto :ERROR1
)



REM Clean working directory
cd "%wd%"

del *.exe 2> NUL
del *.obj 2> NUL
del *.res 2> NUL
del *.log 2> NUL



REM Search and assemble the ressource file
FOR %%A IN (ressources\*.rc) DO (
    set rcFile=%%~nA
    goto :RCFOUND
)

:RCNOTFOUND
    cd %masmLoc%\bin
    ml /coff "%wd%\%pName%.asm" /Fe "%wd%\%pName%.exe" -link /subsystem:%mode% > "%wd%\build.log"
    set errCode=%ERRORLEVEL%
goto :CHECKERR

:RCFOUND
    cd %masmLoc%\bin & rc "%wd%\ressources\%rcFile%.rc"
    ml /coff "%wd%\%pName%.asm" /Fe "%wd%\%pName%.exe" -link /subsystem:%mode% "%wd%\ressources\%rcFile%.res" > "%wd%\build.log"
    set errCode=%ERRORLEVEL%
goto :CHECKERR



:CHECKERR
REM Check potential errors and start program execution
cd "%wd%"

if %errCode% equ 0 (
    %pName%.exe
    echo Program ended with status code %ERRORLEVEL%
) else (
    echo Code building failed! & echo.
    type build.log | more +7
)



REM Remove useless files
del *.obj 2> NUL
del *.res 2> NUL

if "%keepLog%"=="0" (
    del *.log 2> NUL
)



:END
echo. & echo.
pause & exit

:ERROR1
echo.
echo If you did not install MASM32 at this location,
echo please edit run.bat at line 27.

goto :END
