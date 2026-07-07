@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
flutter build apk --debug > codex_build_android.log 2>&1
echo EXITCODE:%ERRORLEVEL%>> codex_build_android.log
