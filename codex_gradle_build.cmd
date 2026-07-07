@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
pushd android
call gradlew.bat assembleDebug > ..\codex_gradle_build.log 2>&1
popd
echo EXITCODE:%ERRORLEVEL%>> codex_gradle_build.log
