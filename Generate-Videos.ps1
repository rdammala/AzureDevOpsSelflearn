#!/usr/bin/env pwsh
# ============================================================================
# Generate-Videos.ps1
# Create video files by combining audio with slides using FFmpeg
# Usage: ./Generate-Videos.ps1
# ============================================================================

param(
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

Write-Host "🎥 Video Generation Tool (FFmpeg-based)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check FFmpeg
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (!$ffmpeg) {
    Write-Host "❌ FFmpeg not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install FFmpeg using:"
    Write-Host "  choco install ffmpeg -y" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or download from: https://ffmpeg.org/download.html" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ FFmpeg found: $(ffmpeg -version | Select-Object -First 1)" -ForegroundColor Green

# Check folders
if (!(Test-Path $AudioFolder)) {
    Write-Host "❌ Audio folder not found: $AudioFolder" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $SlidesFolder)) {
    Write-Host "⚠️  Slides folder not found: $SlidesFolder" -ForegroundColor Yellow
    Write-Host "   Generating test slides..." -ForegroundColor Gray
    
    New-Item -ItemType Directory -Path $SlidesFolder -Force | Out-Null
    
    # Create simple slides for each audio file
    $audioFiles = Get-ChildItem -Path $AudioFolder -Filter "*.mp3"
    foreach ($audio in $audioFiles) {
        $docName = $audio.BaseName
        $docSlideDir = Join-Path $SlidesFolder $docName
        
        New-Item -ItemType Directory -Path $docSlideDir -Force | Out-Null
        
        # Create a simple text-based slide image using PowerShell
        Create-TitleSlide -Text $docName -OutputPath (Join-Path $docSlideDir "slide_00.png")
    }
}

# Create output folder
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "✅ Created output folder: $OutputFolder" -ForegroundColor Green
}

Write-Host "✅ All prerequisites met`n" -ForegroundColor Green

# ============================================================================
# HELPER FUNCTION: CREATE SIMPLE SLIDE IMAGE
# ============================================================================

function Create-TitleSlide {
    param(
        [string]$Text,
        [string]$OutputPath,
        [int]$Width = 1920,
        [int]$Height = 1080
    )
    
    # Try using ImageMagick if available
    $magick = Get-Command magick -ErrorAction SilentlyContinue
    
    if ($magick) {
        try {
            & magick `
                -size "${Width}x${Height}" `
                "xc:#1e3a8a" `
                -font "Arial" `
                -pointsize 72 `
                -fill white `
                -gravity Center `
                -annotate +0+0 "$Text" `
                "$OutputPath" 2>$null
            
            return $true
        }
        catch {
            return $false
        }
    }
    
    # Fallback: Create a colored image with FFmpeg
    try {
        # Create a solid color image with FFmpeg
        & ffmpeg -f lavfi -i color=c='#1e3a8a':s="${Width}x${Height}":d=3 `
            -vf "drawtext=text='$Text':fontsize=72:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2" `
            -y "$OutputPath" 2>$null
        
        return $true
    }
    catch {
        return $false
    }
}

# ============================================================================
# GET AUDIO FILES AND PROCESS
# ============================================================================

$audioFiles = Get-ChildItem -Path $AudioFolder -Filter "*.mp3" | Sort-Object Name

if ($audioFiles.Count -eq 0) {
    Write-Host "❌ No audio files found in: $AudioFolder" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Found $($audioFiles.Count) audio files to process`n" -ForegroundColor Cyan

$successCount = 0
$errorCount = 0

foreach ($audioFile in $audioFiles) {
    $docName = $audioFile.BaseName
    $audioPath = $audioFile.FullName
    $slidesDir = Join-Path $SlidesFolder $docName
    $outputVideo = Join-Path $OutputFolder "$docName.mp4"
    
    Write-Host "🎬 Processing: $docName" -ForegroundColor Yellow
    
    # Check if slides exist
    if (!(Test-Path $slidesDir)) {
        Write-Host "   ⚠️  Slides not found, creating placeholder..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $slidesDir -Force | Out-Null
        Create-TitleSlide -Text "$docName Training" -OutputPath (Join-Path $slidesDir "slide_00.png")
    }
    
    # Get slide files
    $slides = @(Get-ChildItem -Path $slidesDir -Filter "*.png" -ErrorAction SilentlyContinue | Sort-Object Name)
    
    if ($slides.Count -eq 0) {
        Write-Host "   ❌ No slides found in: $slidesDir" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    Write-Host "   📸 Found $($slides.Count) slides" -ForegroundColor Gray
    
    # Get audio duration
    Write-Host "   🔍 Analyzing audio..." -ForegroundColor Gray
    
    try {
        $ffprobeOutput = & ffprobe -v error `
            -show_entries format=duration `
            -of default=noprint_wrappers=1:nokey=1:noinvert_equals=1 `
            "$audioPath" 2>&1
        
        $audioDuration = [int]($ffprobeOutput)
        
        if ($audioDuration -eq 0) {
            Write-Host "   ❌ Could not determine audio duration" -ForegroundColor Red
            $errorCount++
            continue
        }
    }
    catch {
        Write-Host "   ❌ Error analyzing audio: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    Write-Host "   ⏱️  Duration: $audioDuration seconds ($([math]::Floor($audioDuration / 60)):$($audioDuration % 60) minutes)" -ForegroundColor Gray
    
    # Calculate slide display time
    $slidesPerSecond = [math]::Max(0.1, $slides.Count / $audioDuration)
    $slideDisplayTime = [math]::Round(1 / $slidesPerSecond, 2)
    Write-Host "   📽️  Slide duration: $slideDisplayTime seconds" -ForegroundColor Gray
    
    # Create concat file for FFmpeg
    $concatFile = Join-Path $slidesDir "concat.txt"
    
    $concatContent = @()
    foreach ($slide in $slides) {
        $concatContent += "file '$($slide.FullName)'"
        $concatContent += "duration $slideDisplayTime"
    }
    
    Set-Content -Path $concatFile -Value ($concatContent -join "`n")
    
    Write-Host "   🎥 Creating video with FFmpeg..." -ForegroundColor Yellow
    
    try {
        # Create video combining slides + audio
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
        
        # Run FFmpeg
        $process = Start-Process -FilePath "ffmpeg" `
            -ArgumentList $ffmpegArgs `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardError (Join-Path $env:TEMP "ffmpeg_error.log") `
            -RedirectStandardOutput (Join-Path $env:TEMP "ffmpeg_output.log")
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputVideo)) {
            $videoSizeMB = (Get-Item $outputVideo).Length / 1MB
            Write-Host "   ✅ Video created: $(Split-Path -Leaf $outputVideo)" -ForegroundColor Green
            Write-Host "   📊 Size: $([math]::Round($videoSizeMB, 1))MB" -ForegroundColor Green
            $successCount++
        }
        else {
            Write-Host "   ❌ FFmpeg failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    # Cleanup
    Remove-Item -Path $concatFile -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "📊 SUMMARY" -ForegroundColor Cyan
Write-Host "==========" -ForegroundColor Cyan
Write-Host "Videos created: $successCount/$($audioFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

$videoFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp4"
if ($videoFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ Generated videos:" -ForegroundColor Green
    
    $totalSize = 0
    foreach ($video in $videoFiles | Sort-Object Name) {
        $sizeMB = $video.Length / 1MB
        $totalSize += $sizeMB
        Write-Host "  🎥 $($video.Name) ($([math]::Round($sizeMB, 1))MB)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "💾 Total size: $([math]::Round($totalSize, 1))MB" -ForegroundColor White
}

Write-Host ""
Write-Host "📁 Output folder: $OutputFolder" -ForegroundColor Green

if ($successCount -eq $audioFiles.Count) {
    Write-Host "`n✅ All videos generated successfully!" -ForegroundColor Green
}
else {
    Write-Host "`n⚠️  Some videos failed to generate. Check errors above." -ForegroundColor Yellow
}
