#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos.ps1
# Create video files by combining static slide image with audio using FFmpeg
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$SlidesFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos"
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
    Write-Host "[OK] FFmpeg found in PATH" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] FFmpeg not in PATH. Searching WinGet..." -ForegroundColor Yellow
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
    
    $slidePath = $slides[0].FullName
    Write-Host "[INFO] Using slide: $($slides[0].Name)" -ForegroundColor Gray
    
    Write-Host "[INFO] Analyzing audio..." -ForegroundColor Gray
    
    try {
        $ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"
        
        # Get audio duration - use csv format with only duration
        $output = & $ffprobePath -v error -show_entries format=duration -of csv=p=0 "$audioPath" 2>&1
        
        # Extract numeric value from output
        $durationStr = $output -replace '[^0-9.]', ''
        
        if ([string]::IsNullOrWhiteSpace($durationStr)) {
            Write-Host "[ERROR] Could not extract duration from ffprobe output: $output" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        $audioDuration = [int][float]$durationStr
        
        if ($audioDuration -le 0) {
            Write-Host "[ERROR] Invalid audio duration: $audioDuration seconds" -ForegroundColor Red
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
    Write-Host "[INFO] Encoding video with FFmpeg..." -ForegroundColor Yellow
    
    try {
        # Use -loop 1 to loop the image for the duration of audio - much simpler and reliable
        $ffmpegArgs = @(
            "-loop", "1",
            "-i", $slidePath,
            "-i", $audioPath,
            "-c:v", "libx264",
            "-preset", "medium",
            "-crf", "23",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac",
            "-b:a", "128k",
            "-shortest",
            "-y",
            $outputVideo
        )
        
        $process = Start-Process -FilePath $ffmpegPath `
            -ArgumentList $ffmpegArgs `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardError (Join-Path $env:TEMP "ffmpeg_error_$docName.log") `
            -RedirectStandardOutput (Join-Path $env:TEMP "ffmpeg_output_$docName.log")
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputVideo)) {
            $videoSizeMB = (Get-Item $outputVideo).Length / 1MB
            
            if ($videoSizeMB -gt 5) {
                Write-Host "[OK] Video created: $docName.mp4 ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Green
                $successCount++
            }
            else {
                Write-Host "[WARNING] Video suspiciously small ($([math]::Round($videoSizeMB, 2))MB)" -ForegroundColor Yellow
                $errorLog = Get-Content (Join-Path $env:TEMP "ffmpeg_error_$docName.log") 2>/dev/null | Select-Object -First 2
                if ($errorLog) {
                    Write-Host "[DEBUG] FFmpeg error: $errorLog" -ForegroundColor Gray
                }
                $errorCount++
            }
        }
        else {
            Write-Host "[ERROR] FFmpeg failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            $errorLog = Get-Content (Join-Path $env:TEMP "ffmpeg_error_$docName.log") 2>/dev/null | Select-Object -First 2
            if ($errorLog) {
                Write-Host "[DEBUG] $errorLog" -ForegroundColor Gray
            }
            $errorCount++
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    Write-Host ""
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Videos created: $successCount/$($audioFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4" | Where-Object { $_.Length -gt 1MB }
if ($videoFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Successfully created videos:" -ForegroundColor Green
    
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
