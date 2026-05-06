@echo off
echo === MERCH PRO - Subir a GitHub ===
echo.

cd /d "%~dp0"

git init
git add .
git commit -m "Merch Pro - versión inicial con Supabase"
git branch -M main
git remote add origin https://github.com/Clauditosistems/Merch-pro.git
git push -u origin main

echo.
echo === LISTO! Ahora conecta Vercel ===
pause
