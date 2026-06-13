#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos-Final.ps1
# Create videos: loops first title slide with audio (proven, simple, reliable)
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$SlidesFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos"
)

Write-Host "Video Generation Tool - Final" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Checking prerequisites..." -ForegroundColor Yellow

# Check FFmpeg
$ffmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (!$ffmpegPath) {
    $ffmpegPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}

if (!$ffmpegPath -or !(Test-Path $ffmpegPath)) {
    Write-Host "[ERROR] FFmpeg not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] FFmpeg found" -ForegroundColor Green

# Check folders
if (!(Test-Path $AudioFolder)) {
    Write-Host "[ERROR] Audio folder not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Audio folder found" -ForegroundColor Green

if (!(Test-Path $SlidesFolder)) {
    Write-Host "[ERROR] Slides folder not found" -ForegroundColor Red
    Write-Host "[INFO] First run: .\Generate-Slides.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Slides folder found" -ForegroundColor Green

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

Write-Host "[OK] All prerequisites met" -ForegroundColor Green
Write-Host ""

# Get audio files
$audioFiles = Get-ChildItem -Path $AudioFolder -Filter "*.mp3" | Sort-Object Name

if ($audioFiles.Count -eq 0) {
    Write-Host "[ERROR] No audio files found" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($audioFiles.Count) audio files to process" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$errorCount = 0
$ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"

foreach ($audioFile in $audioFiles) {
    $docName = $audioFile.BaseName
    $audioPath = $audioFile.FullName
    $outputVideo = Join-Path $OutputFolder "$docName.mp4"
    
    Write-Host "[INFO] Processing: $docName" -ForegroundColor Yellow
    
    # Find slide folder
    $slideFolder = Get-ChildItem -Path $SlidesFolder -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$docName*" -or $_.Name -eq $docName } | Select-Object -First 1
    
    if (!$slideFolder) {
        Write-Host "[ERROR] No slide folder found for: $docName" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    # Get first slide
    $slideFile = Get-ChildItem -Path $slideFolder.FullName -Filter "*.png" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if (!$slideFile) {
        Write-Host "[ERROR] No slide found in: $($slideFolder.Name)" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    Write-Host "[INFO] Using slide: $($slideFile.Name)" -ForegroundColor Gray
    
    # Get audio duration
    try {
        $output = & $ffprobePath -v error -show_entries format=duration -of csv=p=0 "$audioPath" 2>&1 | Select-Object -First 1
        $durationStr = $output -replace '[^0-9.]', ''
        
        if ([string]::IsNullOrWhiteSpace($durationStr)) {
            Write-Host "[ERROR] Could not get audio duration for: $audioPath" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        $duration = [float]$durationStr
        Write-Host "[INFO] Duration: $([math]::Round($duration, 1)) seconds" -ForegroundColor Gray
    }
    catch {
        Write-Host "[ERROR] Failed to read audio duration: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    # Encode video: loop slide for audio duration
    Write-Host "[INFO] Encoding video..." -ForegroundColor Yellow
    
    try {
        $ffmpegArgs = @(
            "-loop", "1",
            "-i", $slideFile.FullName,
            "-i", $audioPath,
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-crf", "28",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", "192k",
            "-shortest",
            "-y",
            $outputVideo
        )
        
        $process = Start-Process -FilePath $ffmpegPath `
            -ArgumentList $ffmpegArgs `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardError (Join-Path $env:TEMP "ffmpeg_err_$docName.log") `
            -RedirectStandardOutput (Join-Path $env:TEMP "ffmpeg_out_$docName.log")
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputVideo)) {
            $videoSizeMB = (Get-Item $outputVideo).Length / 1MB
            
            if ($videoSizeMB -gt 1.5) {
                Write-Host "[OK] Video created: $docName.mp4 ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Green
                $successCount++
            }
            else {
                Write-Host "[ERROR] Video file too small ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Red
                Remove-Item $outputVideo -Force -ErrorAction SilentlyContinue
                $errorCount++
            }
        }
        else {
            Write-Host "[ERROR] FFmpeg encoding failed" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "[ERROR] Exception during encoding: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# Summary
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
    Write-Host "[WARNING] No valid videos created" -ForegroundColor Yellow
}

Write-Host ""
