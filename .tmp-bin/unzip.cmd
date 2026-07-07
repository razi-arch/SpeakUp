@echo off
setlocal

set "zipFile="
set "destDir="

:parse
if "%~1"=="" goto done
if /I "%~1"=="-d" (
  set "destDir=%~2"
  shift
  shift
  goto parse
)
if /I "%~1"=="-q" (
  shift
  goto parse
)
if /I "%~1"=="-o" (
  shift
  goto parse
)
if /I "%~1"=="-qo" (
  shift
  goto parse
)
if not defined zipFile set "zipFile=%~1"
shift
goto parse

:done
if not defined zipFile (
  echo Missing zip file path>&2
  exit /b 1
)
if not defined destDir (
  echo Missing destination directory>&2
  exit /b 1
)

powershell -NoProfile -Command "Expand-Archive -LiteralPath '%zipFile%' -DestinationPath '%destDir%' -Force"
exit /b %errorlevel%
