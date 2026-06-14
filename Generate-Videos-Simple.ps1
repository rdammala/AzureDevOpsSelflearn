#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos-Simple.ps1
# Create videos by looping title slide with audio (proven approach)
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos",
    
    [Parameter(Mandatory=$false)]
    [string]$SlidesFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides"
)

Write-Host "Video Generation Tool (Simple Loop Approach)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Checking prerequisites..." -ForegroundColor Yellow

# Check FFmpeg
$ffmpegPath = $null
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpeg) {
    $ffmpegPath = $ffmpeg.Source
    Write-Host "[OK] FFmpeg found" -ForegroundColor Green
}
else {
    $wingetPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if ($wingetPath) {
        $ffmpegPath = $wingetPath
        Write-Host "[OK] Found FFmpeg from WinGet" -ForegroundColor Green
    }
    else {
        Write-Host "[ERROR] FFmpeg not found" -ForegroundColor Red
        exit 1
    }
}

# Check folders
if (!(Test-Path $AudioFolder)) {
    Write-Host "[ERROR] Audio folder not found: $AudioFolder" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Audio folder found" -ForegroundColor Green

if (!(Test-Path $SlidesFolder)) {
    Write-Host "[ERROR] Slides folder not found: $SlidesFolder" -ForegroundColor Red
    Write-Host "[INFO] First run Generate-Slides.ps1 to create slides" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Slides folder found" -ForegroundColor Green

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "[OK] Created output folder" -ForegroundColor Green
}

Write-Host "[OK] All prerequisites met" -ForegroundColor Green
Write-Host ""

# Get audio files
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
    $outputVideo = Join-Path $OutputFolder "$docName.mp4"
    
    # Look for the corresponding slide (with numbered prefix)
    $slideFile = $null
    
    # Try to find slide folder
    $slideFolders = Get-ChildItem -Path $SlidesFolder -Directory | Where-Object { $_.Name -like "$docName*" -or $_.Name -eq $docName }
    
    if ($slideFolders.Count -gt 0) {
        # Get first PNG in folder (title slide)
        $slideFile = Get-ChildItem -Path $slideFolders[0].FullName -Filter "*.png" | Select-Object -First 1 -ExpandProperty FullName
    }
    
    if (!$slideFile -or !(Test-Path $slideFile)) {
        Write-Host "[ERROR] No slide found for: $docName" -ForegroundColor Red
        Write-Host "[DEBUG] Looked in: $SlidesFolder for $docName" -ForegroundColor Gray
        $errorCount++
        continue
    }
    
    Write-Host "[INFO] Processing: $docName" -ForegroundColor Yellow
    Write-Host "[INFO] Using slide: $(Split-Path $slideFile -Leaf)" -ForegroundColor Gray
    
    # Get audio duration in seconds
    $ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"
    $output = & $ffprobePath -v error -show_entries format=duration -of csv=p=0 "$audioPath" 2>&1
    $durationStr = $output -replace '[^0-9.]', ''
    
    if ([string]::IsNullOrWhiteSpace($durationStr)) {
        Write-Host "[ERROR] Could not get audio duration" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    $duration = [float]$durationStr
    Write-Host "[INFO] Audio duration: $([math]::Round($duration, 1)) seconds" -ForegroundColor Gray
    
    # Encode video: loop slide image for duration of audio
    Write-Host "[INFO] Encoding video (this may take a few minutes)..." -ForegroundColor Yellow
    
    # Simple approach: loop image with explicit duration matching audio
    # Don't use -shortest, don't use complex filters, just straightforward looping
    $ffmpegArgs = @(
        "-loop", "1",
        "-i", $slideFile,
        "-i", $audioPath,
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-crf", "28",
        "-pix_fmt", "yuv420p",
        "-c:a", "libmp3lame",
        "-b:a", "256k",
        "-t", $duration,
        "-y",
        $outputVideo
    )
    
    $errorLog = Join-Path $env:TEMP "ffmpeg_error_$docName.log"
    $outputLog = Join-Path $env:TEMP "ffmpeg_output_$docName.log"
    
    $process = Start-Process -FilePath $ffmpegPath `
        -ArgumentList $ffmpegArgs `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardError $errorLog `
        -RedirectStandardOutput $outputLog
    
    if ($process.ExitCode -eq 0 -and (Test-Path $outputVideo)) {
        $videoSizeMB = (Get-Item $outputVideo).Length / 1MB
        
        if ($videoSizeMB -gt 1.5) {
            Write-Host "[OK] Video created: $docName.mp4 ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Host "[ERROR] Video file too small ($([math]::Round($videoSizeMB, 1))MB), likely corrupted" -ForegroundColor Red
            Remove-Item $outputVideo -Force -ErrorAction SilentlyContinue
            $errorCount++
        }
    }
    else {
        Write-Host "[ERROR] FFmpeg failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        if (Test-Path $errorLog) {
            $errorContent = Get-Content $errorLog -Raw
            if ($errorContent.Length -gt 500) {
                Write-Host "[DEBUG] Error (first 500 chars): $($errorContent.Substring(0, 500))" -ForegroundColor Gray
            }
            else {
                Write-Host "[DEBUG] Error: $errorContent" -ForegroundColor Gray
            }
        }
        $errorCount++
    }
    
    Write-Host ""
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Videos created: $successCount/$($audioFiles.Count)" -ForegroundColor $(if ($successCount -gt 0) { "Green" } else { "Red" })
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

Write-Host ""
Write-Host "Output folder: $OutputFolder" -ForegroundColor White

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4" -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1500000 }

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
    Write-Host "Total size: $([math]::Round($totalSize, 1))MB" -ForegroundColor Cyan
}
else {
    Write-Host "[WARNING] No valid videos were created" -ForegroundColor Yellow
}

Write-Host ""
