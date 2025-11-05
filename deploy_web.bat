@echo off
title Deploy Flutter Web to GitHub Pages
echo ===============================================
echo     Auto Web Deploy Script for mehdisz
echo ===============================================

:: بخش 1: انتقال به مسیر پروژه
cd /d "C:\Users\Lenovo\Documents\StudioProjects\ehya_proj_01"

echo.
echo [1/5] Cleaning previous build...
flutter clean

echo.
echo [2/5] Building Flutter Web...
flutter build web --release

echo.
echo [3/5] Copying build output to 'webdeploy'...
if not exist "webdeploy" mkdir webdeploy
xcopy build\web webdeploy /E /I /Y >nul

echo.
echo [4/5] Adding and committing changes...
git add .
git commit -m "Automated deploy - %date% %time%"

echo.
echo [5/5] Pushing to GitHub (branch gh-pages)...
git push origin gh-pages --force

echo.
echo ✅ Deployment complete!
echo Site should be live at: https://mehdisz.github.io/well-flow-web/
pause
