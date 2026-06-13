#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos-Dynamic.ps1
# Create karaoke-style videos with scrolling text + audio
# Text content scrolls on screen as audio narrates
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos",
    
    [Parameter(Mandatory=$false)]
    [int]$SlideWidth = 1920,
    
    [Parameter(Mandatory=$false)]
    [int]$SlideHeight = 1080
)

Write-Host "Dynamic Video Generation Tool (Karaoke-Style)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Checking prerequisites..." -ForegroundColor Yellow

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

$magick = Get-Command magick -ErrorAction SilentlyContinue
if (!$magick) {
    Write-Host "[ERROR] ImageMagick not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] ImageMagick found" -ForegroundColor Green

if (!(Test-Path $AudioFolder)) {
    Write-Host "[ERROR] Audio folder not found" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $DocsFolder)) {
    Write-Host "[ERROR] Docs folder not found" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

$tempSlidesFolder = Join-Path $env:TEMP "dynamic_slides_$PID"
if (!(Test-Path $tempSlidesFolder)) {
    New-Item -ItemType Directory -Path $tempSlidesFolder -Force -ErrorAction Stop | Out-Null
}

Write-Host "[OK] All prerequisites met" -ForegroundColor Green
Write-Host ""

# ============================================================================
# CLEAN MARKDOWN TEXT
# ============================================================================

function Clean-MarkdownText {
    param([string]$Content)
    
    $content = $content -replace '```[\s\S]*?```', ''
    $content = $content -replace '#+\s+', ''
    $content = $content -replace '\*\*', ''
    $content = $content -replace '__', ''
    $content = $content -replace '\*', ''
    $content = $content -replace '_', ''
    $content = $content -replace '`([^`]*)`', '$1'
    $content = $content -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    $content = $content -replace '!\[.*?\]\(.*?\)', ''
    $content = $content -replace '---+', ''
    $content = $content -replace '\|', ' '
    $content = $content -replace '\s+', ' '
    
    return $content.Trim()
}

# ============================================================================
# CREATE SCROLLING SLIDES
# ============================================================================

function Create-ScrollingSlides {
    param(
        [string]$Content,
        [string]$OutputPath,
        [string]$DocumentName,
        [int]$MaxCharsPerSlide = 400
    )
    
    $cleanText = Clean-MarkdownText -Content $Content
    $lines = $cleanText -split '\.\s+' | Where-Object { $_.Trim().Length -gt 0 }
    
    if ($lines.Count -eq 0) {
        Write-Host "[DEBUG] No lines extracted from content" -ForegroundColor Gray
        return @()
    }
    
    $slideNum = 1
    $currentText = ""
    $slidePaths = @()
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        
        if (($currentText.Length + $line.Length + 2) -gt $MaxCharsPerSlide -and $currentText.Length -gt 0) {
            # Create slide with current text
            $slidePath = Create-TextSlide -Text $currentText -SlideNum $slideNum -OutputPath $OutputPath -DocumentName $DocumentName
            if ($slidePath -and (Test-Path $slidePath)) { 
                $slidePaths += $slidePath
                $slideNum++
            }
            $currentText = $line
        }
        else {
            if ($currentText.Length -gt 0) {
                $currentText += ". " + $line
            }
            else {
                $currentText = $line
            }
        }
    }
    
    # Last slide
    if ($currentText.Length -gt 0) {
        $slidePath = Create-TextSlide -Text $currentText -SlideNum $slideNum -OutputPath $OutputPath -DocumentName $DocumentName
        if ($slidePath -and (Test-Path $slidePath)) { 
            $slidePaths += $slidePath
        }
    }
    
    return $slidePaths
}

function Create-TextSlide {
    param(
        [string]$Text,
        [int]$SlideNum,
        [string]$OutputPath,
        [string]$DocumentName
    )
    
    $outputFile = Join-Path $OutputPath "$('{0:D3}' -f $SlideNum).png"
    
    # Truncate text to fit on slide
    if ($Text.Length -gt 500) {
        $Text = $Text.Substring(0, 500) + "..."
    }
    
    # Write text to temporary file
    $textFile = Join-Path $OutputPath "text_$SlideNum.txt"
    Set-Content -Path $textFile -Value $Text -Encoding UTF8
    
    try {
        # Use ImageMagick to create slide with text
        $args = @(
            "-size", "1920x1080",
            "xc:rgb(25,45,85)",
            "-gravity", "center",
            "-fill", "rgb(100,200,255)",
            "-font", "Arial",
            "-pointsize", "56",
            "-annotate", "+0-350", $DocumentName,
            "-pointsize", "32",
            "-fill", "rgb(200,220,255)",
            "-gravity", "northwest",
            "-annotate", "+80+150", $Text,
            $outputFile
        )
        
        & magick $args 2>&1 | Out-Null
        
        # Verify slide was created
        if (Test-Path $outputFile) {
            Remove-Item -Path $textFile -Force -ErrorAction SilentlyContinue
            return $outputFile
        }
        else {
            Write-Host "[DEBUG] Slide not created: $outputFile" -ForegroundColor Gray
            return $null
        }
    }
    catch {
        Write-Host "[DEBUG] Error: $($_.Exception.Message)" -ForegroundColor Gray
        Remove-Item -Path $textFile -Force -ErrorAction SilentlyContinue
        return $null
    }
}

# ============================================================================
# MAIN PROCESSING
# ============================================================================

$audioFiles = Get-ChildItem -Path $AudioFolder -Filter "*.mp3" | Sort-Object Name

if ($audioFiles.Count -eq 0) {
    Write-Host "[ERROR] No audio files found" -ForegroundColor Red
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
    $docPath = Join-Path $DocsFolder "$docName.md"
    
    Write-Host "[INFO] Processing: $docName" -ForegroundColor Yellow
    
    if (!(Test-Path $docPath)) {
        Write-Host "[ERROR] Document not found: $docPath" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    try {
        # Read document content
        $mdContent = Get-Content -Path $docPath -Raw
        
        # Create temp folder for slides
        $tempSlideFolder = Join-Path $tempSlidesFolder $docName
        Remove-Item -Path $tempSlideFolder -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $tempSlideFolder -Force | Out-Null
        
        Write-Host "[INFO] Creating scrolling slides..." -ForegroundColor Gray
        $slidePaths = Create-ScrollingSlides -Content $mdContent -OutputPath $tempSlideFolder -DocumentName $docName
        
        if ($slidePaths.Count -eq 0) {
            Write-Host "[ERROR] Failed to create slides" -ForegroundColor Red
            Write-Host "[DEBUG] Checking temp folder: $(Get-ChildItem $tempSlideFolder -Filter '*.png' -ErrorAction SilentlyContinue | Measure-Object).Count files" -ForegroundColor Gray
            $errorCount++
            continue
        }
        
        Write-Host "[INFO] Created $($slidePaths.Count) slides" -ForegroundColor Gray
        
        # Get audio duration
        $ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"
        $output = & $ffprobePath -v error -show_entries format=duration -of csv=p=0 "$audioPath" 2>&1
        $durationStr = $output -replace '[^0-9.]', ''
        
        if ([string]::IsNullOrWhiteSpace($durationStr)) {
            Write-Host "[ERROR] Could not get audio duration" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        $audioDuration = [int][float]$durationStr
        $slideDisplayTime = [math]::Round(($audioDuration / $slidePaths.Count), 2)
        
        Write-Host "[INFO] Duration: $audioDuration seconds | Slides: $($slidePaths.Count) | Per-slide: $slideDisplayTime sec" -ForegroundColor Gray
        
        # Create concat file
        $concatFile = Join-Path $tempSlideFolder "concat.txt"
        $concatContent = @()
        
        foreach ($slide in $slidePaths) {
            $concatContent += "file '$slide'"
            $concatContent += "duration $slideDisplayTime"
        }
        
        Set-Content -Path $concatFile -Value ($concatContent -join "`n")
        
        Write-Host "[INFO] Encoding video..." -ForegroundColor Yellow
        
        $ffmpegArgs = @(
            "-f", "concat",
            "-safe", "0",
            "-i", $concatFile,
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
                Write-Host "[WARNING] Video suspiciously small" -ForegroundColor Yellow
                $errorCount++
            }
        }
        else {
            Write-Host "[ERROR] FFmpeg failed" -ForegroundColor Red
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
# CLEANUP & SUMMARY
# ============================================================================

Remove-Item -Path $tempSlidesFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Videos created: $successCount/$($audioFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4" | Where-Object { $_.Length -gt 5MB }
if ($videoFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Generated karaoke-style videos:" -ForegroundColor Green
    
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
Write-Host ""

if ($successCount -eq $audioFiles.Count) {
    Write-Host "[SUCCESS] All karaoke-style videos generated!" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Some videos failed" -ForegroundColor Yellow
}
