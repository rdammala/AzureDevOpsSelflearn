#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos-Karaoke.ps1
# Create karaoke-style videos with multiple slides + scrolling text
# Each slide shows for calculated duration as audio narrates
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos"
)

Write-Host "Karaoke Video Generation Tool" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
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

# Check ImageMagick
$magick = Get-Command magick -ErrorAction SilentlyContinue
if (!$magick) {
    $magickPath = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
    if (!(Test-Path $magickPath)) {
        Write-Host "[ERROR] ImageMagick not found at $magickPath" -ForegroundColor Red
        exit 1
    }
}
else {
    $magickPath = $magick.Source
}
Write-Host "[OK] ImageMagick found" -ForegroundColor Green

# Check folders
if (!(Test-Path $AudioFolder)) {
    Write-Host "[ERROR] Audio folder not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Audio folder found" -ForegroundColor Green

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

Write-Host "[OK] All prerequisites met" -ForegroundColor Green
Write-Host ""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Clean-Text {
    param([string]$Text)
    
    # Remove markdown formatting
    $text = $text -replace '```[\s\S]*?```', ''
    $text = $text -replace '#+\s+', ''
    $text = $text -replace '\*\*', ''
    $text = $text -replace '__', ''
    $text = $text -replace '\*', ''
    $text = $text -replace '_', ''
    $text = $text -replace '`', ''
    $text = $text -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    $text = $text -replace '!\[.*?\]\(.*?\)', ''
    $text = $text -replace '---+', ''
    $text = $text -replace '\|', ' '
    $text = $text -replace '\s+', ' '
    
    return $text.Trim()
}

function Create-TextSlide {
    param(
        [string]$Text,
        [string]$OutputFile,
        [string]$Title,
        [int]$SlideNumber,
        [int]$TotalSlides,
        [string]$MagickExe
    )
    
    # Escape special characters that might break ImageMagick
    $Text = $Text -replace '"', '\"'
    $Text = $Text -replace "'", "\'"
    
    # Wrap text to reasonable line length
    $wrappedText = ""
    $currentLine = ""
    $maxLineLength = 70
    
    $words = @()
    foreach ($word in $Text -split '\s+') {
        if ($word.Length -gt 0) {
            $words += $word
        }
    }
    
    foreach ($word in $words) {
        if (($currentLine.Length + $word.Length + 1) -gt $maxLineLength) {
            if ($currentLine) {
                $wrappedText += $currentLine + "`n"
            }
            $currentLine = $word
        }
        else {
            if ($currentLine) {
                $currentLine += " " + $word
            }
            else {
                $currentLine = $word
            }
        }
    }
    if ($currentLine) {
        $wrappedText += $currentLine
    }
    
    try {
        # Create a temporary text file to avoid quoting issues
        $textFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $textFile -Value $wrappedText -Encoding UTF8 -Force
        
        # Use convert (simpler than magick command) with label for text
        $outputDir = Split-Path $OutputFile
        $filename = Split-Path $OutputFile -Leaf
        
        # Create base image with background
        & $MagickExe `
            -size 1920x1080 `
            "xc:rgb(35,60,100)" `
            -gravity North `
            -pointsize 44 `
            -fill "rgb(120,200,255)" `
            -font Arial `
            -annotate +0+60 "$Title" `
            "$OutputFile" `
            2>&1 | Out-Null
        
        if (Test-Path $OutputFile) {
            # Now add text overlay using -annotate with file
            & $MagickExe "$OutputFile" `
                -gravity Center `
                -pointsize 32 `
                -fill "rgb(200,220,255)" `
                -annotate +0+50 "$wrappedText" `
                "$OutputFile" `
                2>&1 | Out-Null
            
            Remove-Item $textFile -Force -ErrorAction SilentlyContinue
            
            if (Test-Path $OutputFile) {
                return $true
            }
        }
        
        Remove-Item $textFile -Force -ErrorAction SilentlyContinue
        return $false
    }
    catch {
        Write-Host "[DEBUG] Error creating slide: $($_.Exception.Message)" -ForegroundColor Gray
        return $false
    }
}

function Create-KaraokeSlidesForDocument {
    param(
        [string]$Content,
        [string]$OutputPath,
        [string]$DocumentTitle,
        [string]$MagickExe
    )
    
    $cleanContent = Clean-Text -Text $Content
    
    # Split into sentences
    $sentences = $cleanContent -split '\.\s+' | Where-Object { $_.Trim().Length -gt 20 }
    
    if ($sentences.Count -eq 0) {
        Write-Host "[DEBUG] No content extracted" -ForegroundColor Gray
        return @()
    }
    
    # Group sentences into slides (roughly 3 sentences per slide)
    $slides = @()
    $currentSlide = ""
    $slideCount = 0
    
    foreach ($sentence in $sentences) {
        $sentence = $sentence.Trim()
        
        if ($currentSlide.Length -gt 0) {
            $testSlide = $currentSlide + ". " + $sentence
        }
        else {
            $testSlide = $sentence
        }
        
        # If slide would be too long, create current slide and start new one
        if ($testSlide.Length -gt 600) {
            if ($currentSlide.Length -gt 0) {
                $slideCount++
                $slides += @{ Text = $currentSlide; Number = $slideCount }
            }
            $currentSlide = $sentence
        }
        else {
            if ($currentSlide.Length -gt 0) {
                $currentSlide += ". " + $sentence
            }
            else {
                $currentSlide = $sentence
            }
        }
    }
    
    # Last slide
    if ($currentSlide.Length -gt 0) {
        $slideCount++
        $slides += @{ Text = $currentSlide; Number = $slideCount }
    }
    
    if ($slides.Count -eq 0) {
        return @()
    }
    
    # Create slide images
    $slidePaths = @()
    
    foreach ($slide in $slides) {
        $slideFile = Join-Path $OutputPath "slide_$($slide.Number).png"
        
        $created = Create-TextSlide `
            -Text $slide.Text `
            -OutputFile $slideFile `
            -Title $DocumentTitle `
            -SlideNumber $slide.Number `
            -TotalSlides $slides.Count `
            -MagickExe $MagickExe
        
        if ($created -and (Test-Path $slideFile)) {
            $slidePaths += $slideFile
            Write-Host "[OK] Created slide $($slide.Number)/$($slides.Count)" -ForegroundColor Green
        }
        else {
            Write-Host "[ERROR] Failed to create slide $($slide.Number)" -ForegroundColor Red
        }
    }
    
    return $slidePaths
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
$tempBaseFolder = Join-Path $env:TEMP "karaoke_slides_$PID"

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
        # Create temp folder for this document's slides
        $tempSlideFolder = Join-Path $tempBaseFolder $docName
        Remove-Item -Path $tempSlideFolder -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $tempSlideFolder -Force | Out-Null
        
        # Read document
        $mdContent = Get-Content -Path $docPath -Raw
        
        # Create karaoke slides
        Write-Host "[INFO] Creating slides..." -ForegroundColor Gray
        $slidePaths = Create-KaraokeSlidesForDocument -Content $mdContent -OutputPath $tempSlideFolder -DocumentTitle $docName -MagickExe $magickPath
        
        if ($slidePaths.Count -eq 0) {
            Write-Host "[ERROR] Failed to create slides" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        Write-Host "[INFO] Created $($slidePaths.Count) slides" -ForegroundColor Green
        
        # Get audio duration
        $ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"
        $output = & $ffprobePath -v error -show_entries format=duration -of csv=p=0 "$audioPath" 2>&1
        $durationStr = $output -replace '[^0-9.]', ''
        
        if ([string]::IsNullOrWhiteSpace($durationStr)) {
            Write-Host "[ERROR] Could not get audio duration" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        $duration = [float]$durationStr
        $slideDuration = $duration / $slidePaths.Count
        
        Write-Host "[INFO] Duration: $([math]::Round($duration, 1))s | Slides: $($slidePaths.Count) | Per-slide: $([math]::Round($slideDuration, 2))s" -ForegroundColor Gray
        
        # Create FFmpeg concat file with absolute paths
        $concatFile = Join-Path $tempSlideFolder "concat.txt"
        $concatLines = @()
        
        foreach ($slide in $slidePaths) {
            # Use absolute path and convert backslashes to forward slashes for FFmpeg
            $absPath = (Resolve-Path $slide).Path
            $ffmpegPath = $absPath -replace '\\', '/'
            
            $concatLines += "file '$ffmpegPath'"
            $concatLines += "duration $slideDuration"
        }
        
        Set-Content -Path $concatFile -Value ($concatLines -join "`n") -Encoding UTF8
        
        Write-Host "[INFO] Encoding video (this may take several minutes)..." -ForegroundColor Yellow
        
        # Test: Log the concat file for debugging
        Write-Host "[DEBUG] Concat file created with $($slidePaths.Count) slides" -ForegroundColor Gray
        
        # Encode with concat demuxer
        $ffmpegArgs = @(
            "-f", "concat",
            "-safe", "0",
            "-i", $concatFile,
            "-i", $audioPath,
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-crf", "28",
            "-pix_fmt", "yuv420p",
            "-c:a", "libmp3lame",
            "-b:a", "256k",
            "-shortest",
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
                Write-Host "[OK] Karaoke video created: $docName.mp4 ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Green
                $successCount++
            }
            else {
                Write-Host "[WARNING] Video small ($([math]::Round($videoSizeMB, 1))MB) but valid" -ForegroundColor Yellow
                $successCount++
            }
        }
        else {
            Write-Host "[ERROR] FFmpeg failed with code: $($process.ExitCode)" -ForegroundColor Red
            
            if (Test-Path $errorLog) {
                $errorContent = Get-Content $errorLog -Raw
                $firstError = ($errorContent -split "`n" | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 3) -join " | "
                Write-Host "[DEBUG] Error: $firstError" -ForegroundColor Gray
            }
            
            if (Test-Path $outputLog) {
                $outputContent = Get-Content $outputLog -Raw
                if ($outputContent.Length -gt 200) {
                    Write-Host "[DEBUG] Output (truncated): $($outputContent.Substring(0, 200))" -ForegroundColor Gray
                }
            }
            
            $errorCount++
        }
    }
    catch {
        Write-Host "[ERROR] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# ============================================================================
# CLEANUP & SUMMARY
# ============================================================================

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Karaoke videos created: $successCount/$($audioFiles.Count)" -ForegroundColor $(if ($successCount -gt 0) { "Green" } else { "Red" })
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

Write-Host ""
Write-Host "Output folder: $OutputFolder" -ForegroundColor White

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4" -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1500000 }

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
    Write-Host "Total size: $([math]::Round($totalSize, 1))MB" -ForegroundColor Cyan
}
else {
    Write-Host "[WARNING] No valid videos were created" -ForegroundColor Yellow
}

Write-Host ""

# Cleanup temp folder
Remove-Item -Path $tempBaseFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[INFO] Done!" -ForegroundColor Green
