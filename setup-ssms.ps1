<#
.SYNOPSIS
    SSMS & Microsoft Tools Installer
.DESCRIPTION
    Интерактивный скрипт для скачивания и установки SSMS и инструментов Microsoft
.EXAMPLE
    irm https://raw.githubusercontent.com/ВАШ_ЛОГИН/ВАШ_РЕПОЗИТОРИЙ/main/setup-ssms.ps1 | iex
.NOTES
    Author: Ваше Имя
    Version: 1.0
#>

# Определяем, запущен ли скрипт локально или удаленно
$isRemote = $PSScriptRoot -eq $null -or $PSScriptRoot -eq ""

if ($isRemote) {
    Write-Host "Запуск из удаленного репозитория..." -ForegroundColor Cyan
}

# Цветное меню
function Write-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      SSMS & Microsoft Tools Installer" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Download SSMS 22" -ForegroundColor Yellow
    Write-Host "  [2] Download Microsoft Tool" -ForegroundColor Yellow
    Write-Host "  [3] Download BOTH files" -ForegroundColor Green
    Write-Host "  [4] Install SSMS (after download)" -ForegroundColor Magenta
    Write-Host "  [5] Install Microsoft Tool" -ForegroundColor Magenta
    Write-Host "  [6] Download & Install SSMS" -ForegroundColor Red
    Write-Host "  [7] Check downloaded files" -ForegroundColor Gray
    Write-Host "  [8] Open Downloads folder" -ForegroundColor Gray
    Write-Host "  [9] Open 1C Login page (login.1c.ru)" -ForegroundColor Cyan
    Write-Host "  [0] Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Функция скачивания с прогрессом
function Download-File {
    param($Url, $FileName, $Description)
    
    $downloadPath = "$env:USERPROFILE\Downloads"
    $outputPath = "$downloadPath\$FileName"
    
    Write-Host ""
    Write-Host "Downloading: $Description" -ForegroundColor Yellow
    Write-Host "File: $FileName" -ForegroundColor Gray
    Write-Host "To: $outputPath" -ForegroundColor Gray
    Write-Host ""
    
    try {
        Invoke-RestMethod -Uri $Url -OutFile $outputPath -UseBasicParsing
        Write-Host "✓ SUCCESS! Downloaded: $FileName" -ForegroundColor Green
        
        $fileSize = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
        Write-Host "  Size: $fileSize MB" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Host "✗ ERROR: $_" -ForegroundColor Red
        return $false
    }
}

# Функция проверки файлов
function Check-Files {
    $downloadPath = "$env:USERPROFILE\Downloads"
    $files = @(
        @{Name="SSMS_22_Setup.exe"; Desc="SSMS 22"},
        @{Name="Microsoft_Tool_Setup.exe"; Desc="Microsoft Tool"}
    )
    
    Write-Host ""
    Write-Host "Checking Downloads folder..." -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($file in $files) {
        $path = "$downloadPath\$($file.Name)"
        if (Test-Path $path) {
            $size = [math]::Round((Get-Item $path).Length / 1MB, 2)
            Write-Host "  ✓ $($file.Desc): $($file.Name) ($size MB)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($file.Desc): $($file.Name) - NOT FOUND" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Главное меню
do {
    Write-Menu
    $choice = Read-Host "  Select option"
    
    switch ($choice) {
        "1" {
            Download-File -Url "https://aka.ms/ssms/22/release/vs_SSMS.exe" -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "2" {
            Download-File -Url "https://go.microsoft.com/fwlink/?linkid=2344626&culture=en-us" -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "3" {
            Download-File -Url "https://aka.ms/ssms/22/release/vs_SSMS.exe" -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            Download-File -Url "https://go.microsoft.com/fwlink/?linkid=2344626&culture=en-us" -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "4" {
            $ssmsPath = "$env:USERPROFILE\Downloads\SSMS_22_Setup.exe"
            if (Test-Path $ssmsPath) {
                Write-Host "`nStarting SSMS installation..." -ForegroundColor Yellow
                Start-Process $ssmsPath -Wait
                Write-Host "Installation completed!" -ForegroundColor Green
            } else {
                Write-Host "`n✗ SSMS installer not found! Please download first (option 1 or 3)" -ForegroundColor Red
            }
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "5" {
            $toolPath = "$env:USERPROFILE\Downloads\Microsoft_Tool_Setup.exe"
            if (Test-Path $toolPath) {
                Write-Host "`nStarting Microsoft Tool installation..." -ForegroundColor Yellow
                Start-Process $toolPath -Wait
                Write-Host "Installation completed!" -ForegroundColor Green
            } else {
                Write-Host "`n✗ Tool installer not found! Please download first (option 2 or 3)" -ForegroundColor Red
            }
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "6" {
            Download-File -Url "https://aka.ms/ssms/22/release/vs_SSMS.exe" -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            Write-Host "`nStarting installation..." -ForegroundColor Yellow
            Start-Process "$env:USERPROFILE\Downloads\SSMS_22_Setup.exe" -Wait
            Write-Host "Installation completed!" -ForegroundColor Green
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "7" {
            Check-Files
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "8" {
            Write-Host "`nOpening Downloads folder..." -ForegroundColor Yellow
            Invoke-Item "$env:USERPROFILE\Downloads"
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "9" {
            $url = "https://login.1c.ru/login"
            Write-Host "`nOpening 1C login page in your default browser..." -ForegroundColor Cyan
            Write-Host "URL: $url" -ForegroundColor Gray
            try {
                Start-Process $url
                Write-Host "`n✓ Browser window should open." -ForegroundColor Green
            }
            catch {
                Write-Host "`n✗ Failed to open browser. Please visit the URL manually." -ForegroundColor Red
                Write-Host "  $url" -ForegroundColor Yellow
            }
            Write-Host "`nPress any key to return to menu..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "0" {
            Write-Host "`nExiting... Goodbye!" -ForegroundColor Green
            exit
        }
        default {
            Write-Host "`nInvalid option! Press any key..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
} while ($choice -ne "0")
