# 🛠️ SSMS Tools Installer

[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/aydarmxvd/ssms-tools)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub release](https://img.shields.io/badge/version-1.7-red.svg)](https://github.com/aydarmxvd/ssms-tools)

**PowerShell script for automatic downloading and installation of Microsoft SSMS, CryptoPro, and utilities with an interactive menu.**

## 🚀 Quick Start

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/aydarmxvd/ssms-tools/main/setup-ssms.ps1 | iex
```

## 📋 What the Script Does

The script provides an interactive menu with 13 options for:

- Downloading Microsoft SQL Server Management Studio (SSMS) 22
- Downloading additional Microsoft tools
- Downloading CryptoPro CSP from Google Drive
- Downloading utilities archive from Google Drive
- Installing downloaded software
- Searching for files anywhere on your system
- Opening useful 1C portals ([login.1c.ru](https://login.1c.ru), [developer.1c.ru](https://developer.1c.ru))

## 📖 Menu Options Description

| Option | Command | What It Does | Technical Details |
|---|---|---|---|
| **1** | `Download SSMS 22` | Downloads SQL Server Management Studio 22 | • Source: `aka.ms/ssms/22/release/vs_SSMS.exe` • Size: ~1.5-2 GB • Saves to: `%USERPROFILE%\Downloads\SSMS_22_Setup.exe` |
| **2** | `Download Microsoft Tool` | Downloads additional Microsoft tool | • Source: `go.microsoft.com/fwlink/?linkid=2344626` • Size: ~100-200 MB • Saves to: `%USERPROFILE%\Downloads\Microsoft_Tool_Setup.exe` |
| **3** | `Download BOTH files` | Downloads both SSMS and Microsoft Tool sequentially | • Executes options 1 and 2 in order • Total size: ~1.6-2.2 GB |
| **4** | `Install SSMS` | Installs SSMS (searches entire system for installer) | • Searches all drives for `SSMS_22_Setup.exe` • Launches with `Start-Process -Wait` • Waits for installation to complete |
| **5** | `Install Microsoft Tool` | Installs Microsoft Tool (searches entire system) | • Searches all drives for `Microsoft_Tool_Setup.exe` • Launches with `Start-Process -Wait` |
| **6** | `Download & Install SSMS` | Downloads SSMS then automatically installs it | • First downloads fresh copy • Immediately launches installer |
| **7** | `Search files on entire system` | Searches all drives for all managed files | • Checks C:, D:, etc. • Shows all found copies with paths and sizes • Reports missing files |
| **8** | `Open Downloads folder` | Opens Windows Explorer in Downloads folder | • Runs: `Invoke-Item "$env:USERPROFILE\Downloads"` |
| **9** | `Open 1C Login page` | Opens 1C login portal in browser | • URL: `https://login.1c.ru/login` • For 1cfresh, 1cbo, and other cloud services |
| **10** | `Open 1C Developer portal` | Opens 1C developer portal | • URL: `https://developer.1c.ru` • Documentation, SDK, and developer tools |
| **11** | `Download Utilities` | Downloads utilities.zip from Google Drive and extracts | • Source: Google Drive (your shared file) • Automatically extracts to `%USERPROFILE%\Downloads\Utilities` |
| **12** | `Download CryptoPro` | Downloads CryptoPro CSP 5.0 from Google Drive | • Source: Google Drive (your shared file) • Size: ~80-100 MB • Option to install immediately |
| **0** | `Exit` | Exits the script | • Closes the interactive menu |

## 🔧 What Happens When Downloading (Options 1,2,3,11,12)

Before downloading, the script **automatically checks**:

1. **Are there old copies of this file anywhere on your system?**

- Searches all drives (C:, D:, etc.)
- Shows all found copies with their locations and sizes
1. **Prompts you with options:**

- `[Y] Yes` - Delete ALL old copies, then download fresh
- `[N] No` - Keep old copies, download new one (may cause duplicates)
- `[S] Skip` - Cancel download completely
1. **Checks Downloads folder:**

- If file already exists in Downloads, asks whether to overwrite
1. **Downloads the file** with progress indication and size display

## 🔍 What Happens When Searching (Option 7)

The script performs a **deep system scan**:

```
# What gets checked:
- All physical drives (C:\, D:\, E:\, etc.)
- All user folders
- All system folders (with access permissions)
- Up to 5 copies of each file type

# For each found file, displays:
- ✓ Status (found/missing)
- File name
- Size in MB and GB
- Full file path
```

**Example output:**

```
========================================
     SEARCHING FILES ON ENTIRE SYSTEM
========================================

────────────────────────────────────────
  ✓ SSMS 22 FOUND!
      File: SSMS_22_Setup.exe
      Size: 1520 MB (1.48 GB)
      Path: C:\Users\Admin\Downloads\SSMS_22_Setup.exe

────────────────────────────────────────
  ✗ Utilities pack: utilities.zip - NOT FOUND ANYWHERE ON SYSTEM

========================================
  Found: 3 of 4 files
========================================
```

## 💡 Usage Examples

### Example 1: Fresh installation on new PC

```
1. Run script
2. Choose [3] - Download both SSMS and Microsoft Tool
3. Wait for downloads to complete
4. Choose [4] - Install SSMS
5. Choose [5] - Install Microsoft Tool
6. Choose [11] - Download and extract utilities
7. Choose [12] - Download CryptoPro
```

### Example 2: Update SSMS only

```
1. Run script
2. Choose [6] - Download & Install SSMS (automatically deletes old versions)
3. Wait for completion
```

### Example 3: Check what files are already downloaded

```
1. Run script
2. Choose [7] - Search files on entire system
3. View all found files with their locations
```

### Example 4: Quick access to 1C portals

```
1. Run script
2. Choose [9] - Open 1C Login page
3. Choose [10] - Open 1C Developer portal
```

## ⚙️ Technical Architecture

### Core Functions

| Function | Purpose | Key Commands |
|---|---|---|
| `Download-File` | Downloads files with progress | `Invoke-RestMethod`, `WebClient` |
| `Search-FileOnSystem` | Searches all drives | `Get-ChildItem -Recurse` |
| `Remove-OldFiles` | Deletes old versions | `Remove-Item -Force` |
| `Check-Files` | Reports all found files | Integrated search + display |
| `Extract-Zip` | Unpacks ZIP archives | `[System.IO.Compression.ZipFile]` |

### Supported Download Sources

- **Microsoft official**: `aka.ms`, `microsoft.com`
- **Google Drive**: Direct links via `drive.usercontent.google.com`
- **Any HTTP/HTTPS**: Standard web downloads

### File Management Logic

```
User selects download option
         ↓
Search entire system for existing copies
         ↓
┌─────────────────────────────────────┐
│ Found?                               │
├─────────────────────────────────────┤
│ YES → Show all copies with sizes     │
│       Ask: Delete? (Y/N/S)          │
│         Y → Delete all old copies    │
│         N → Keep, download anyway   │
│         S → Cancel download          │
│                                       │
│ NO → Proceed to download              │
└─────────────────────────────────────┘
         ↓
Check Downloads folder for existing file
         ↓
Ask: Overwrite? (if exists)
         ↓
Download new file with progress
         ↓
Save to: %USERPROFILE%\Downloads\
```

## 🔐 Security Features

| Feature | Implementation |
|---|---|
| **No data collection** | Script doesn't send any information externally |
| **Official sources only** | Microsoft files from Microsoft domains only |
| **User confirmation** | Always asks before deleting files |
| **Error handling** | Graceful failure with informative messages |
| **Access checking** | Skips protected system folders automatically |

## 📊 System Requirements

| Requirement | Minimum |
|---|---|
| **OS** | Windows 7/8/10/11, Windows Server 2012+ |
| **PowerShell** | Version 5.1 or higher |
| **Disk space** | 5 GB free (for all downloads) |
| **RAM** | 512 MB (1 GB recommended for extraction) |
| **Internet** | Stable connection (downloads up to 2 GB) |

## 🔧 Troubleshooting

| Problem | Solution |
|---|---|
| **"Access Denied" error** | Right-click PowerShell → "Run as Administrator" |
| **"Execution policy" error** | Run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| **Google Drive download fails** | Script uses alternative method automatically |
| **Browser doesn't open for options 9-10** | Manually visit: [https://login.1c.ru](https://login.1c.ru) or [https://developer.1c.ru](https://developer.1c.ru) |
| **Download keeps failing** | Check internet connection, disable VPN, try again |
| **File not found after download** | Check `C:\Users\YOUR_USERNAME\Downloads` |
| **ZIP extraction fails** | Ensure enough disk space, run as Administrator |

## 📦 Manual Installation (Without GitHub)

If you can't use the one-liner command:

```
# 1. Download the script manually
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aydarmxvd/ssms-tools/main/setup-ssms.ps1" -OutFile "$env:TEMP\setup-ssms.ps1"

# 2. Run it
& "$env:TEMP\setup-ssms.ps1"
```

## 📝 Version History

| Version | Date | Changes |
|---|---|---|
| 1.7 | 05.06.2026 | • Added system-wide file search before download • Added option to delete old files automatically • Improved Google Drive download handling • Added CryptoPro and utilities from Google Drive |
| 1.6 | 05.06.2026 | • Added system-wide search for all files (option 7) • Installation now finds files anywhere on system • Shows full paths and sizes for all found files |
| 1.5 | 05.06.2026 | • Added CryptoPro download from Google Drive • Added utilities.zip download and auto-extract • Added 1C Developer portal link |
| 1.0 | 05.06.2026 | • Initial release with SSMS download and installation |

## 🤝 Contributing

1. Fork the repository
1. Create a feature branch (`git checkout -b feature/AmazingFeature`)
1. Commit changes (`git commit -m 'Add AmazingFeature'`)
1. Push to branch (`git push origin feature/AmazingFeature`)
1. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` file for more information.

## 🙏 Acknowledgments

- Microsoft for SSMS and tools distribution
- CryptoPro for CSP software
- Google Drive for file hosting

## 📞 Support

- **GitHub Issues**: [Create an issue](https://github.com/aydarmxvd/ssms-tools/issues)
- **Repository**: [https://github.com/aydarmxvd/ssms-tools](https://github.com/aydarmxvd/ssms-tools)

**Created by aydarmxvd** | **Version 1.7** | **2026**

