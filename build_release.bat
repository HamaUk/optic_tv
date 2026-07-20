@echo off
echo Building Optic TV securely with Dart Obfuscation and Split Debug Info...

REM Create a directory to store the debug symbols
mkdir build\app\outputs\symbols

REM Build the APK using obfuscation
flutter build apk --release --obfuscate --split-debug-info=build\app\outputs\symbols

echo.
echo Build complete! Your APK is located in: build\app\outputs\flutter-apk\app-release.apk
echo WARNING: Keep the symbols folder safe. You will need it to read crash reports!
pause
