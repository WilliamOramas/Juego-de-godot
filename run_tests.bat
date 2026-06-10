@echo off
setlocal

where godot >nul 2>&1
if %ERRORLEVEL%==0 (
  godot --headless -s res://tests/run_tests.gd
  exit /b %ERRORLEVEL%
)

where godot4 >nul 2>&1
if %ERRORLEVEL%==0 (
  godot4 --headless -s res://tests/run_tests.gd
  exit /b %ERRORLEVEL%
)

echo Godot no esta en PATH. Ejecuta manualmente:
echo   godot --headless -s res://tests/run_tests.gd
exit /b 1
