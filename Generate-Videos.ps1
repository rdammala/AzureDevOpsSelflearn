#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos.ps1
# Create video files by combining audio with slides using FFmpeg
# Usage: ./Generate-Videos.ps1
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$FFmpegPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$SlidesFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos",
    
    [Parameter(Mandatory=$false)]
    [int]$SlideDisplaySeconds = 3
)

# ============================================================================
# VALIDATION
# ============================================================================

Write-Host "Video Generation Tool (FFmpeg-based)" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Checking prerequisites..." -ForegroundColor Yellow

$ffmpegPath = $null

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpeg) {
    $ffmpegPath = $ffmpeg.Source
    Write-Host "[OK] FFmpeg found in PATH: $ffmpegPath" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] FFmpeg not in PATH. Searching common locations..." -ForegroundColor Yellow
    $searchPaths = @(
        "C:\ffmpeg\bin\ffmpeg.exe",
        "C:\Program Files\ffmpeg\bin\ffmpeg.exe",
        "C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe",
        "C:\ProgramData\chocolatey\bin\ffmpeg.exe",
        "C:\tools\ffmpeg\ffmpeg.exe"
    )
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            $ffmpegPath = $path
            Write-Host "[OK] Found FFmpeg at: $ffmpegPath" -ForegroundColor Green
            break
        }
    }
    
    if (!$ffmpegPath) {
        Write-Host "[WARNING] Checking WinGet packages..." -ForegroundColor Yellow
        $wingetPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if ($wingetPath) {
            $ffmpegPath = $wingetPath
            Write-Host "[OK] Found FFmpeg from WinGet: $ffmpegPath" -ForegroundColor Green
        }
    }
    
    if (!$ffmpegPath) {
        Write-Host "[ERROR] FFmpeg not found in PATH or common locations" -ForegroundColor Red
        Write-Host "Please install FFmpeg:" -ForegroundColor Yellow
        Write-Host "  Option 1: winget install ffmpeg" -ForegroundColor Yellow
        Write-Host "  Option 2: Download from https://ffmpeg.org/download.html" -ForegroundColor Yellow
        Write-Host "Then add to PATH or specify full path in script" -ForegroundColor Yellow
        exit 1
    }
}

if (!(Test-Path $AudioFolder)) {
    Write-Host "[ERROR] Audio folder not found: $AudioFolder" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $SlidesFolder)) {
    Write-Host "[WARNING] Slides folder not found: $SlidesFolder" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $SlidesFolder -Force | Out-Null
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "[OK] Created output folder: $OutputFolder" -ForegroundColor Green
}

Write-Host "[OK] All prerequisites met" -ForegroundColor Green
Write-Host ""

# ============================================================================
# GET AUDIO FILES AND PROCESS
# ============================================================================

$audioFiles = Get-ChildItem -Path $AudioFolder -Filter "*.mp3" | Sort-Object Name

if ($audioFiles.Count -eq 0) {
    Write-Host "[ERROR] No audio files found in: $AudioFolder" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($audioFiles.Count) audio files to process" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($audioFile in $audioFiles) {
    $docName = $audioFile.BaseName
    $audioPath = $audioFile.FullName
    $slidesDir = Join-Path $SlidesFolder $docName
    $outputVideo = Join-Path $OutputFolder "$docName.mp4"
    
    Write-Host "[INFO] Processing: $docName" -ForegroundColor Yellow
    
    if (!(Test-Path $slidesDir)) {
        Write-Host "[WARNING] Slides not found, creating placeholder..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $slidesDir -Force | Out-Null
    }
    
    $slides = @(Get-ChildItem -Path $slidesDir -Filter "*.png" -ErrorAction SilentlyContinue | Sort-Object Name)
    
    if ($slides.Count -eq 0) {
        Write-Host "[ERROR] No slides found in: $slidesDir" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    Write-Host "[INFO] Found $($slides.Count) slides" -ForegroundColor Gray
    
    Write-Host "[INFO] Analyzing audio..." -ForegroundColor Gray
    
    try {
        $ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"
        
        # Get audio duration directly
        $duration = & $ffprobePath -v error -show_entries format=duration -of default=nokey=1 "$audioPath" 2>&1
        
        if ($duration) {
            $audioDuration = [int][float]($duration | Select-Object -First 1)
        }
        else {
            Write-Host "[ERROR] ffprobe returned no output" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        if ($audioDuration -le 0) {
            Write-Host "[ERROR] Invalid audio duration: $audioDuration" -ForegroundColor Red
            $errorCount++
            continue
        }
    }
    catch {
        Write-Host "[ERROR] Error analyzing audio: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    Write-Host "[INFO] Duration: $audioDuration seconds" -ForegroundColor Gray
    
    $slidesPerSecond = [math]::Max(0.1, $slides.Count / $audioDuration)
    $slideDisplayTime = [math]::Round(1 / $slidesPerSecond, 2)
    
    $concatFile = Join-Path $slidesDir "concat.txt"
    
    $concatContent = @()
    foreach ($slide in $slides) {
        $concatContent += "file '$($slide.FullName)'"
        $concatContent += "duration $slideDisplayTime"
    }
    
    Set-Content -Path $concatFile -Value ($concatContent -join "`n")
    
    Write-Host "[INFO] Creating video with FFmpeg..." -ForegroundColor Yellow
    
    try {
        $ffmpegCmd = if ($ffmpegPath) { $ffmpegPath } else { "ffmpeg" }
        
        $ffmpegArgs = @(
            "-f", "concat",
            "-safe", "0",
            "-i", $concatFile,
            "-i", $audioPath,
            "-c:v", "libx264",
            "-preset", "faster",
            "-crf", "23",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", "128k",
            "-shortest",
            "-y",
            $outputVideo
        )
        
        $process = Start-Process -FilePath $ffmpegCmd `
            -ArgumentList $ffmpegArgs `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardError (Join-Path $env:TEMP "ffmpeg_error.log") `
            -RedirectStandardOutput (Join-Path $env:TEMP "ffmpeg_output.log")
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputVideo)) {
            $videoSizeMB = (Get-Item $outputVideo).Length / 1MB
            Write-Host "[OK] Video created: $docName.mp4 ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Host "[ERROR] FFmpeg failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    Remove-Item -Path $concatFile -Force -ErrorAction SilentlyContinue
    Write-Host ""
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Videos created: $successCount/$($audioFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4"
if ($videoFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Generated videos:" -ForegroundColor Green
    
    $totalSize = 0
    foreach ($video in $videoFiles | Sort-Object Name) {
        $sizeMB = $video.Length / 1MB
        $totalSize += $sizeMB
        Write-Host "  [VIDEO] $($video.Name) ($([math]::Round($sizeMB, 1))MB)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Total size: $([math]::Round($totalSize, 1))MB" -ForegroundColor White
}

Write-Host ""
Write-Host "Output folder: $OutputFolder" -ForegroundColor Green

if ($successCount -eq $audioFiles.Count) {
    Write-Host ""
    Write-Host "[SUCCESS] All videos generated successfully!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "[WARNING] Some videos failed. Check errors above." -ForegroundColor Yellow
}
