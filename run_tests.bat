@echo off
setlocal

where godot >nul 2>&1
if %ERRORLEVEL%==0 (
  godot --headless res://tests/run_tests.tscn
  exit /b %ERRORLEVEL%
)

where godot4 >nul 2>&1
if %ERRORLEVEL%==0 (
  godot4 --headless res://tests/run_tests.tscn
  exit /b %ERRORLEVEL%
)

echo Godot no esta en PATH. Ejecuta manualmente:
echo   godot --headless res://tests/run_tests.tscn
exit /b 1
