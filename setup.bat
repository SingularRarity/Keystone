@echo off
REM Keystone setup script for Windows (batch version)
REM This is a simple wrapper that calls the PowerShell script

powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
pause