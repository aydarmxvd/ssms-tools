<#
.SYNOPSIS
    SSMS & Microsoft Tools Installer
.DESCRIPTION
    Интерактивный скрипт для скачивания и установки SSMS, инструментов Microsoft,
    утилит и КриптоПро с Google Drive. При скачивании проверяет наличие старых
    файлов в системе и удаляет их перед загрузкой новых.
.EXAMPLE
    irm https://raw.githubusercontent.com/aydarmxvd/ssms-tools/main/setup-ssms.ps1 | iex
.NOTES
    Author: aydarmxvd
    Version: 1.7
    GitHub: https://github.com/aydarmxvd/ssms-tools
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
    Write-Host "  [7] Search files on entire system" -ForegroundColor Gray
    Write-Host "  [8] Open Downloads folder" -ForegroundColor Gray
    Write-Host "  [9] Open 1C Login page (login.1c.ru)" -ForegroundColor Cyan
    Write-Host "  [10] Open 1C Developer portal (developer.1c.ru)" -ForegroundColor Cyan
    Write-Host "  [11] Download Utilities (ZIP from Google Drive)" -ForegroundColor Yellow
    Write-Host "  [12] Download CryptoPro (from Google Drive)" -ForegroundColor Yellow
    Write-Host "  [0] Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Функция поиска файлов по всей системе
function Search-FileOnSystem {
    param($FileName, $Description, $ShowProgress = $true)
    
    if ($ShowProgress) {
        Write-Host "  Searching for $Description..." -ForegroundColor Yellow
    }
    
    # Определяем диски для поиска
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
    $foundPaths = @()
    
    foreach ($drive in $drives) {
        $searchPath = "$($drive.Root)"
        if ($ShowProgress) {
            Write-Host "    Searching on $searchPath ..." -ForegroundColor Gray
        }
        
        try {
            $results = Get-ChildItem -Path $searchPath -Filter $FileName -Recurse -ErrorAction SilentlyContinue -Force |
                       Select-Object -First 5
            foreach ($result in $results) {
                $foundPaths += $result.FullName
            }
        }
        catch {
            continue
        }
    }
    
    return $foundPaths
}

# Функция удаления старых файлов
function Remove-OldFiles {
    param($FileName, $Description)
    
    Write-Host ""
    Write-Host "Checking for existing $Description files on system..." -ForegroundColor Cyan
    
    $foundPaths = Search-FileOnSystem -FileName $FileName -Description $Description -ShowProgress $false
    
    if ($foundPaths.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠ Found existing $Description files:" -ForegroundColor Yellow
        foreach ($path in $foundPaths) {
            if (Test-Path $path) {
                $size = [math]::Round((Get-Item $path).Length / 1MB, 2)
                Write-Host "    • $path ($size MB)" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "Do you want to delete old files before downloading new ones?" -ForegroundColor Yellow
        Write-Host "  [Y] Yes - delete all old files and download fresh copy" -ForegroundColor Green
        Write-Host "  [N] No  - keep old files, download anyway (may cause duplicates)" -ForegroundColor Red
        Write-Host "  [S] Skip - don't download new file" -ForegroundColor Gray
        Write-Host ""
        $choice = Read-Host "Select (Y/N/S)"
        
        if ($choice -eq 'Y' -or $choice -eq 'y') {
            Write-Host ""
            $deletedCount = 0
            foreach ($path in $foundPaths) {
                try {
                    Remove-Item -Path $path -Force -ErrorAction Stop
                    Write-Host "  ✓ Deleted: $path" -ForegroundColor Green
                    $deletedCount++
                }
                catch {
                    Write-Host "  ✗ Failed to delete: $path" -ForegroundColor Red
                    Write-Host "    Error: $_" -ForegroundColor Gray
                }
            }
            Write-Host ""
            Write-Host "✓ Deleted $deletedCount old file(s)" -ForegroundColor Green
            return $true
        }
        elseif ($choice -eq 'S' -or $choice -eq 's') {
            Write-Host ""
            Write-Host "Download cancelled by user." -ForegroundColor Gray
            return $false
        }
        else {
            Write-Host ""
            Write-Host "Keeping old files. New file will be downloaded to Downloads folder." -ForegroundColor Yellow
            return $true
        }
    }
    else {
        Write-Host "  No existing $Description files found." -ForegroundColor Green
        return $true
    }
}

# Функция скачивания с прогрессом (поддержка Google Drive)
function Download-File {
    param($Url, $FileName, $Description)
    
    $downloadPath = "$env:USERPROFILE\Downloads"
    $outputPath = "$downloadPath\$FileName"
    
    Write-Host ""
    Write-Host "Downloading: $Description" -ForegroundColor Yellow
    Write-Host "File: $FileName" -ForegroundColor Gray
    Write-Host "To: $outputPath" -ForegroundColor Gray
    Write-Host ""
    
    # Проверяем, нет ли уже файла в папке Загрузки
    if (Test-Path $outputPath) {
        Write-Host "⚠ File already exists in Downloads folder!" -ForegroundColor Yellow
        Write-Host "  Existing file: $outputPath" -ForegroundColor Gray
        $size = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
        Write-Host "  Size: $size MB" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Overwrite? (Y/N)" -ForegroundColor Yellow
        $overwrite = Read-Host
        if ($overwrite -ne 'Y' -and $overwrite -ne 'y') {
            Write-Host "Download cancelled." -ForegroundColor Gray
            return $false
        }
        Write-Host ""
    }
    
    # Специальная обработка для Google Drive
    if ($Url -like "*drive.usercontent.google.com*" -or $Url -like "*drive.google.com*") {
        Write-Host "Google Drive file detected. Starting download..." -ForegroundColor Cyan
        
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $outputPath)
            Write-Host "✓ SUCCESS! Downloaded: $FileName" -ForegroundColor Green
            
            $fileSize = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
            Write-Host "  Size: $fileSize MB" -ForegroundColor Gray
            Write-Host "  Path: $outputPath" -ForegroundColor Gray
            return $true
        }
        catch {
            Write-Host "Trying alternative download method..." -ForegroundColor Yellow
            try {
                Invoke-RestMethod -Uri $Url -OutFile $outputPath -UseBasicParsing
                Write-Host "✓ SUCCESS! Downloaded: $FileName" -ForegroundColor Green
                $fileSize = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
                Write-Host "  Size: $fileSize MB" -ForegroundColor Gray
                Write-Host "  Path: $outputPath" -ForegroundColor Gray
                return $true
            }
            catch {
                Write-Host "✗ ERROR: $_" -ForegroundColor Red
                return $false
            }
        }
    }
    else {
        try {
            Invoke-RestMethod -Uri $Url -OutFile $outputPath -UseBasicParsing
            Write-Host "✓ SUCCESS! Downloaded: $FileName" -ForegroundColor Green
            
            $fileSize = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
            Write-Host "  Size: $fileSize MB" -ForegroundColor Gray
            Write-Host "  Path: $outputPath" -ForegroundColor Gray
            return $true
        }
        catch {
            Write-Host "✗ ERROR: $_" -ForegroundColor Red
            return $false
        }
    }
}

# Функция проверки файлов (с поиском по всей системе)
function Check-Files {
    $downloadPath = "$env:USERPROFILE\Downloads"
    $files = @(
        @{Name="SSMS_22_Setup.exe"; Desc="SSMS 22"},
        @{Name="Microsoft_Tool_Setup.exe"; Desc="Microsoft Tool"},
        @{Name="utilities.zip"; Desc="Utilities pack"},
        @{Name="CryptoPro-5.0.13003.exe"; Desc="CryptoPro"}
    )
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "     SEARCHING FILES ON ENTIRE SYSTEM" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This may take a few minutes depending on disk size..." -ForegroundColor Gray
    Write-Host ""
    
    $foundCount = 0
    $totalCount = $files.Count
    
    foreach ($file in $files) {
        Write-Host "────────────────────────────────────────" -ForegroundColor DarkGray
        $foundPaths = Search-FileOnSystem -FileName $file.Name -Description $file.Desc
        
        if ($foundPaths.Count -gt 0) {
            Write-Host "  ✓ $($file.Desc) FOUND!" -ForegroundColor Green
            foreach ($path in $foundPaths) {
                if (Test-Path $path) {
                    $size = [math]::Round((Get-Item $path).Length / 1MB, 2)
                    $sizeGB = [math]::Round((Get-Item $path).Length / 1GB, 2)
                    Write-Host "      File: $($file.Name)" -ForegroundColor Gray
                    Write-Host "      Size: $size MB ($sizeGB GB)" -ForegroundColor Gray
                    Write-Host "      Path: $path" -ForegroundColor Cyan
                    Write-Host ""
                }
            }
            $foundCount++
        } else {
            Write-Host "  ✗ $($file.Desc): $($file.Name) - NOT FOUND ANYWHERE ON SYSTEM" -ForegroundColor Red
            Write-Host ""
        }
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Found: $foundCount of $totalCount files" -ForegroundColor $(if ($foundCount -eq $totalCount) { "Green" } else { "Yellow" })
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($foundCount -eq $totalCount) {
        Write-Host "✓ All files are downloaded!" -ForegroundColor Green
        Write-Host "  You can now use options 4, 5, 11 to install/extract" -ForegroundColor Gray
    } elseif ($foundCount -gt 0) {
        Write-Host "⚠ Some files are missing. Use options 1,2,11,12 to download them." -ForegroundColor Yellow
        Write-Host "  Downloaded files go to: $downloadPath" -ForegroundColor Gray
    } else {
        Write-Host "✗ No files found. Use options 1,2,11,12 to download." -ForegroundColor Red
        Write-Host "  Files will be saved to: $downloadPath" -ForegroundColor Gray
    }
    Write-Host ""
}

# Функция распаковки ZIP
function Extract-Zip {
    param($ZipPath, $DestinationPath)
    
    try {
        if (-not (Test-Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
        }
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestinationPath, $true)
        Write-Host "✓ ZIP extracted to: $DestinationPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to extract ZIP: $_" -ForegroundColor Red
        return $false
    }
}

# Главное меню
do {
    Write-Menu
    $choice = Read-Host "  Select option"
    
    switch ($choice) {
        "1" {
            $shouldContinue = Remove-OldFiles -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            if ($shouldContinue) {
                Download-File -Url "https://aka.ms/ssms/22/release/vs_SSMS.exe" -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            }
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "2" {
            $shouldContinue = Remove-OldFiles -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            if ($shouldContinue) {
                Download-File -Url "https://go.microsoft.com/fwlink/?linkid=2344626&culture=en-us" -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            }
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "3" {
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "  Downloading BOTH files" -ForegroundColor White
            Write-Host "========================================" -ForegroundColor Cyan
            
            $shouldContinue1 = Remove-OldFiles -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            if ($shouldContinue1) {
                Download-File -Url "https://aka.ms/ssms/22/release/vs_SSMS.exe" -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            }
            
            $shouldContinue2 = Remove-OldFiles -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            if ($shouldContinue2) {
                Download-File -Url "https://go.microsoft.com/fwlink/?linkid=2344626&culture=en-us" -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "4" {
            Write-Host "`nSearching for SSMS installer on your system..." -ForegroundColor Yellow
            $foundPaths = Search-FileOnSystem -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            
            if ($foundPaths.Count -gt 0) {
                $ssmsPath = $foundPaths[0]
                Write-Host "`nFound SSMS installer at: $ssmsPath" -ForegroundColor Green
                Write-Host "Starting SSMS installation..." -ForegroundColor Yellow
                Start-Process $ssmsPath -Wait
                Write-Host "Installation completed!" -ForegroundColor Green
            } else {
                Write-Host "`n✗ SSMS installer not found anywhere on system!" -ForegroundColor Red
                Write-Host "  Please download first (option 1 or 3)" -ForegroundColor Yellow
            }
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "5" {
            Write-Host "`nSearching for Microsoft Tool installer on your system..." -ForegroundColor Yellow
            $foundPaths = Search-FileOnSystem -FileName "Microsoft_Tool_Setup.exe" -Description "Microsoft Tool"
            
            if ($foundPaths.Count -gt 0) {
                $toolPath = $foundPaths[0]
                Write-Host "`nFound Microsoft Tool installer at: $toolPath" -ForegroundColor Green
                Write-Host "Starting Microsoft Tool installation..." -ForegroundColor Yellow
                Start-Process $toolPath -Wait
                Write-Host "Installation completed!" -ForegroundColor Green
            } else {
                Write-Host "`n✗ Microsoft Tool installer not found anywhere on system!" -ForegroundColor Red
                Write-Host "  Please download first (option 2 or 3)" -ForegroundColor Yellow
            }
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "6" {
            $shouldContinue = Remove-OldFiles -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
            if ($shouldContinue) {
                Download-File -Url "https://aka.ms/ssms/22/release/vs_SSMS.exe" -FileName "SSMS_22_Setup.exe" -Description "SSMS 22"
                Write-Host "`nStarting installation..." -ForegroundColor Yellow
                Start-Process "$env:USERPROFILE\Downloads\SSMS_22_Setup.exe" -Wait
                Write-Host "Installation completed!" -ForegroundColor Green
            }
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
        "10" {
            $url = "https://developer.1c.ru/"
            Write-Host "`nOpening 1C Developer portal in your default browser..." -ForegroundColor Cyan
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
        "11" {
            $shouldContinue = Remove-OldFiles -FileName "utilities.zip" -Description "Utilities pack"
            if ($shouldContinue) {
                $zipUrl = "https://drive.usercontent.google.com/download?id=1oDziHUB9GPKo_R8Kq0OgLaoJsw0pjGmq&export=download&confirm=t"
                $zipName = "utilities.zip"
                $extractPath = "$env:USERPROFILE\Downloads\Utilities"
                
                Write-Host "`nDownloading utilities pack from Google Drive..." -ForegroundColor Yellow
                $result = Download-File -Url $zipUrl -FileName $zipName -Description "Utilities pack (ZIP)"
                
                if ($result) {
                    $zipPath = "$env:USERPROFILE\Downloads\$zipName"
                    if (Test-Path $zipPath) {
                        Write-Host "`nExtracting ZIP archive..." -ForegroundColor Yellow
                        Extract-Zip -ZipPath $zipPath -DestinationPath $extractPath
                        Write-Host "`nUtilities extracted to: $extractPath" -ForegroundColor Green
                    }
                }
            }
            
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "12" {
            $shouldContinue = Remove-OldFiles -FileName "CryptoPro-5.0.13003.exe" -Description "CryptoPro"
            if ($shouldContinue) {
                $cryptoUrl = "https://drive.usercontent.google.com/download?id=1Yb4D-IH5dGWy0M_7cClzigxU2TqhWggh&export=download&confirm=t"
                $cryptoName = "CryptoPro-5.0.13003.exe"
                
                $result = Download-File -Url $cryptoUrl -FileName $cryptoName -Description "CryptoPro 5.0"
                
                if ($result) {
                    $cryptoPath = "$env:USERPROFILE\Downloads\$cryptoName"
                    if (Test-Path $cryptoPath) {
                        Write-Host "`nDo you want to install CryptoPro now? (y/N)" -ForegroundColor Yellow
                        $install = Read-Host
                        if ($install -eq 'y') {
                            Write-Host "Starting CryptoPro installation..." -ForegroundColor Yellow
                            Start-Process $cryptoPath -Wait
                            Write-Host "Installation completed!" -ForegroundColor Green
                        }
                    }
                }
            }
            
            Write-Host "`nPress any key to continue..."
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
