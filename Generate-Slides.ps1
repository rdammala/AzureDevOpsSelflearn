#!/usr/bin/env pwsh
# ============================================================================
# Generate-Slides.ps1
# Create basic slide images from markdown documents using ImageMagick
# Usage: ./Generate-Slides.ps1
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$SlidesFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    
    [Parameter(Mandatory=$false)]
    [int]$SlideWidth = 1920,
    
    [Parameter(Mandatory=$false)]
    [int]$SlideHeight = 1080
)

Write-Host "Slide Generation Tool (ImageMagick-based)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Checking prerequisites..." -ForegroundColor Yellow

$magick = Get-Command magick -ErrorAction SilentlyContinue
if (!$magick) {
    Write-Host "[ERROR] ImageMagick not found" -ForegroundColor Red
    Write-Host "Install: choco install imagemagick -y" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] ImageMagick found" -ForegroundColor Green

if (!(Test-Path $DocsFolder)) {
    Write-Host "[ERROR] Documents folder not found: $DocsFolder" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $SlidesFolder)) {
    New-Item -ItemType Directory -Path $SlidesFolder -Force | Out-Null
    Write-Host "[OK] Created slides folder: $SlidesFolder" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# GET MARKDOWN FILES
# ============================================================================

$mdFiles = @(Get-ChildItem -Path $DocsFolder -Filter "*.md" -File | 
             Where-Object { $_.Name -notmatch "^(README|GENERATE|QUICK-START|READY-TO-USE|INDEX)" } |
             Sort-Object Name)

if ($mdFiles.Count -eq 0) {
    Write-Host "[ERROR] No markdown files found in: $DocsFolder" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($mdFiles.Count) markdown files" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$errorCount = 0

# ============================================================================
# CREATE SLIDES
# ============================================================================

foreach ($mdFile in $mdFiles) {
    $docName = $mdFile.BaseName
    $docFolder = Join-Path $SlidesFolder $docName
    
    Write-Host "[INFO] Processing: $docName" -ForegroundColor Yellow
    
    if (!(Test-Path $docFolder)) {
        New-Item -ItemType Directory -Path $docFolder -Force | Out-Null
    }
    
    $slideFile = Join-Path $docFolder "01.png"
    
    try {
        $title = $docName -replace "^\d+-", "" -replace "-", " "
        
        $bgColor = "rgb(25,45,85)"
        $textColor = "white"
        $accentColor = "rgb(100,200,255)"
        
        $magickArgs = @(
            "-size", "$($SlideWidth)x$($SlideHeight)",
            "xc:$bgColor",
            "-gravity", "center",
            "-font", "Arial",
            "-pointsize", "72",
            "-fill", $accentColor,
            "-annotate", "+0-200", $title,
            "-pointsize", "36",
            "-fill", $textColor,
            "-annotate", "+0+150", "Professional Training Guide",
            "-pointsize", "24",
            "-fill", "rgb(150,150,150)",
            "-annotate", "+0+250", (Get-Date -Format "yyyy-MM-dd"),
            $slideFile
        )
        
        & magick $magickArgs 2>&1 | Out-Null
        
        if (Test-Path $slideFile) {
            $sizeKB = (Get-Item $slideFile).Length / 1KB
            Write-Host "[OK] Slide created: $docName/01.png ($([math]::Round($sizeKB, 1))KB)" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Host "[ERROR] Failed to create slide" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Slides created: $successCount/$($mdFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

Write-Host ""
Write-Host "Slides folder: $SlidesFolder" -ForegroundColor Green
Write-Host ""

if ($successCount -eq $mdFiles.Count) {
    Write-Host "[SUCCESS] All slides generated! You can now run Generate-Videos.ps1" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Some slides failed. Check errors above." -ForegroundColor Yellow
}
