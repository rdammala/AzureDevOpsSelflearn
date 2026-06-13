#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos-Transcript.ps1
# Create lyrical-style videos with transcript text on slides
# Shows key content sections as audio narrates (like karaoke lyrics)
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos-transcript"
)

Write-Host "Transcript Video Generation Tool (Lyrical Style)" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
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

# Check ImageMagick
$magickPath = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
if (!(Test-Path $magickPath)) {
    Write-Host "[ERROR] ImageMagick not found at: $magickPath" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] ImageMagick found" -ForegroundColor Green

# Check folders
if (!(Test-Path $AudioFolder)) {
    Write-Host "[ERROR] Audio folder not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Audio folder found" -ForegroundColor Green

if (!(Test-Path $DocsFolder)) {
    Write-Host "[ERROR] Docs folder not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Docs folder found" -ForegroundColor Green

if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}
Write-Host "[OK] All prerequisites met" -ForegroundColor Green
Write-Host ""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Extract-MainContent {
    param([string]$MarkdownPath)
    
    $content = Get-Content -Path $MarkdownPath -Raw
    
    # Remove front matter, code blocks, and metadata
    $content = $content -replace '---[\s\S]*?---', ''
    $content = $content -replace '```[\s\S]*?```', ''
    $content = $content -replace '#+\s+', ''
    
    # Remove links but keep text
    $content = $content -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    
    # Remove images
    $content = $content -replace '!\[.*?\]\(.*?\)', ''
    
    # Remove horizontal rules
    $content = $content -replace '---+', ''
    
    # Extract sentences (split by periods)
    $sentences = @()
    $currentSentence = ""
    
    foreach ($char in $content.ToCharArray()) {
        $currentSentence += $char
        
        if ($char -eq '.' -and $currentSentence.Trim().Length -gt 20) {
            $sentences += $currentSentence.Trim()
            $currentSentence = ""
        }
    }
    
    if ($currentSentence.Trim().Length -gt 0) {
        $sentences += $currentSentence.Trim()
    }
    
    return $sentences | Where-Object { $_.Length -gt 30 }
}

function Create-ContentSlide {
    param(
        [string]$Title,
        [string]$Content,
        [string]$OutputFile,
        [int]$SlideNumber
    )
    
    # Wrap text to fit on slide
    $wrappedText = ""
    $lineLength = 0
    $maxLineLength = 80
    
    foreach ($word in $Content -split '\s+') {
        if ($word.Length -eq 0) { continue }
        
        if (($lineLength + $word.Length + 1) -gt $maxLineLength) {
            $wrappedText += "`n"
            $lineLength = 0
        }
        
        $wrappedText += $word + " "
        $lineLength += $word.Length + 1
    }
    
    try {
        # Create slide using ImageMagick
        # Alternate background colors for visual distinction
        $bgColor = "rgb(35,60,100)"
        if ($SlideNumber % 2 -eq 0) {
            $bgColor = "rgb(45,70,115)"
        }
        
        # Create base image
        & $magickPath `
            -size 1920x1080 `
            "xc:$bgColor" `
            -gravity North `
            -pointsize 48 `
            -fill "rgb(120,200,255)" `
            -font Arial-Bold `
            -annotate +0+80 "$Title" `
            -pointsize 32 `
            -fill "rgb(200,220,255)" `
            -gravity Center `
            -annotate +0+50 "$wrappedText" `
            "$OutputFile" `
            2>&1 | Out-Null
        
        if (Test-Path $OutputFile) {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Write-Host "[DEBUG] Slide creation error: $($_.Exception.Message)" -ForegroundColor Gray
        return $false
    }
}

function Create-TranscriptSlides {
    param(
        [string]$Content,
        [string]$OutputPath,
        [string]$DocumentTitle
    )
    
    $sentences = Extract-MainContent -MarkdownPath $Content
    
    if ($sentences.Count -eq 0) {
        return @()
    }
    
    # Group sentences into logical chunks (2-3 sentences per slide for readability)
    $slides = @()
    $currentSlide = ""
    $sentenceCount = 0
    
    foreach ($sentence in $sentences) {
        $sentence = $sentence.Trim()
        
        if ($currentSlide.Length -gt 0) {
            $testSlide = $currentSlide + " " + $sentence
        }
        else {
            $testSlide = $sentence
        }
        
        # Keep slide under 400 chars for readability
        if ($testSlide.Length -gt 400 -and $sentenceCount -gt 0) {
            $slides += @{ Text = $currentSlide; Number = $slides.Count + 1 }
            $currentSlide = $sentence
            $sentenceCount = 1
        }
        else {
            if ($currentSlide.Length -gt 0) {
                $currentSlide += " " + $sentence
            }
            else {
                $currentSlide = $sentence
            }
            $sentenceCount++
        }
    }
    
    if ($currentSlide.Length -gt 0) {
        $slides += @{ Text = $currentSlide; Number = $slides.Count + 1 }
    }
    
    if ($slides.Count -eq 0) {
        return @()
    }
    
    # Create slide images
    $slidePaths = @()
    
    foreach ($slide in $slides) {
        $slideFile = Join-Path $OutputPath "slide_$($slide.Number.ToString('D3')).png"
        
        $created = Create-ContentSlide `
            -Title $DocumentTitle `
            -Content $slide.Text `
            -OutputFile $slideFile `
            -SlideNumber $slide.Number
        
        if ($created -and (Test-Path $slideFile)) {
            $slidePaths += $slideFile
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
$ffprobePath = $ffmpegPath -replace "ffmpeg.exe", "ffprobe.exe"
$tempBaseFolder = Join-Path $env:TEMP "transcript_videos_$PID"

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
        # Create temp folder
        $tempSlideFolder = Join-Path $tempBaseFolder $docName
        Remove-Item -Path $tempSlideFolder -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $tempSlideFolder -Force | Out-Null
        
        # Create transcript slides
        Write-Host "[INFO] Creating transcript slides..." -ForegroundColor Gray
        $slidePaths = Create-TranscriptSlides -Content $docPath -OutputPath $tempSlideFolder -DocumentTitle $docName
        
        if ($slidePaths.Count -eq 0) {
            Write-Host "[ERROR] Failed to create slides" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        Write-Host "[INFO] Created $($slidePaths.Count) slides" -ForegroundColor Green
        
        # Get audio duration
        try {
            $output = & $ffprobePath -v error -show_entries format=duration -of csv=p=0 "$audioPath" 2>&1 | Select-Object -First 1
            $durationStr = $output -replace '[^0-9.]', ''
            
            if ([string]::IsNullOrWhiteSpace($durationStr)) {
                Write-Host "[ERROR] Could not get audio duration" -ForegroundColor Red
                $errorCount++
                continue
            }
            
            $duration = [float]$durationStr
            $slideDuration = $duration / $slidePaths.Count
            
            Write-Host "[INFO] Duration: $([math]::Round($duration, 1))s | Slides: $($slidePaths.Count) | Per-slide: $([math]::Round($slideDuration, 2))s" -ForegroundColor Gray
        }
        catch {
            Write-Host "[ERROR] Failed to get duration: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        # Create FFmpeg concat file
        $concatFile = Join-Path $tempSlideFolder "concat.txt"
        $concatLines = @()
        
        foreach ($slide in $slidePaths) {
            $absPath = (Resolve-Path $slide).Path -replace '\\', '/'
            $concatLines += "file '$absPath'"
            $concatLines += "duration $slideDuration"
        }
        
        Set-Content -Path $concatFile -Value ($concatLines -join "`n") -Encoding UTF8
        
        Write-Host "[INFO] Encoding video..." -ForegroundColor Yellow
        
        # Encode with FFmpeg
        $ffmpegArgs = @(
            "-f", "concat",
            "-safe", "0",
            "-i", $concatFile,
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
            -RedirectStandardError (Join-Path $env:TEMP "ffmpeg_transcript_err_$docName.log") `
            -RedirectStandardOutput (Join-Path $env:TEMP "ffmpeg_transcript_out_$docName.log")
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputVideo)) {
            $videoSizeMB = (Get-Item $outputVideo).Length / 1MB
            
            if ($videoSizeMB -gt 0.5) {
                Write-Host "[OK] Transcript video created: $docName.mp4 ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Green
                $successCount++
            }
            else {
                Write-Host "[ERROR] Video too small ($([math]::Round($videoSizeMB, 1))MB)" -ForegroundColor Red
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
        Write-Host "[ERROR] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
}

# ============================================================================
# CLEANUP & SUMMARY
# ============================================================================

Remove-Item -Path $tempBaseFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Transcript videos created: $successCount/$($audioFiles.Count)" -ForegroundColor $(if ($successCount -gt 0) { "Green" } else { "Red" })
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

Write-Host ""
Write-Host "Output folder: $OutputFolder" -ForegroundColor White

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4" -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 500000 }

if ($videoFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Generated transcript videos:" -ForegroundColor Green
    
    $totalSize = 0
    foreach ($video in $videoFiles | Sort-Object Name) {
        $sizeMB = $video.Length / 1MB
        $totalSize += $sizeMB
        Write-Host "  [VIDEO] $($video.Name) ($([math]::Round($sizeMB, 1))MB)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Total size: $([math]::Round($totalSize, 1))MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "[INFO] Transcript videos show educational content with narrated audio" -ForegroundColor Cyan
Write-Host "[INFO] Perfect for learning, training, and knowledge sharing" -ForegroundColor Cyan
