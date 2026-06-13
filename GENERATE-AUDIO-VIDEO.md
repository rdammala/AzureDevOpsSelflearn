# Generate Training Audio & Video (Free Azure Tools)

**Complete automation to create professional training audio and videos using Azure free tier + open source tools**

---

## 📋 Prerequisites (All Free)

### 1. Azure Account (Free Tier)
- **Text-to-Speech (TTS):** 500,000 free characters/month (we need ~200K)
- **Blob Storage:** 5GB free (we'll use ~1GB for audio+video)
- **Cognitive Services:** Free tier available

**Sign up:** https://azure.microsoft.com/free/

### 2. Local Tools (All Free & Open Source)
- **PowerShell 7+** (already have)
- **FFmpeg** (video creation tool)
- **ImageMagick** (image processing)
- **Python 3** (optional, for markdown parsing)

**Install FFmpeg:**
```powershell
# Windows: Using Chocolatey (if installed)
choco install ffmpeg

# Or download: https://ffmpeg.org/download.html
# Extract to: C:\Program Files\ffmpeg\bin
```

---

## 🚀 Step 1: Create Azure Text-to-Speech Resource (Free)

### 1.1 Create via Azure Portal

```
1. Go to: https://portal.azure.com
2. Click "+ Create a resource"
3. Search: "Speech"
4. Click "Speech services"
5. Create:
   - Name: "AzureDevOpsAudio"
   - Region: "East US" (free tier available)
   - Pricing: "Free F0"
   - Resource Group: "rg-training-free"
6. Click "Create"
7. Go to resource → Keys & Endpoint
8. Copy: Key and Endpoint (you'll need these)
```

### 1.2 Setup PowerShell Variables

```powershell
# Save these in a config file or environment variables
$ttsKey = "YOUR_KEY_FROM_AZURE"
$ttsRegion = "eastus"
$ttsEndpoint = "https://$ttsRegion.tts.speech.microsoft.com"

# Test connection
$headers = @{
    "Ocp-Apim-Subscription-Key" = $ttsKey
    "Content-Type" = "application/ssml+xml"
    "X-Microsoft-OutputFormat" = "audio-16khz-32kbitrate-mono-mp3"
}

# Quick test
Invoke-WebRequest -Uri "$ttsEndpoint/cognitiveservices/v1" `
    -Headers $headers `
    -Body "<speak><voice name='en-US-AriaNeural'>Test</voice></speak>" `
    -Method Post -OutFile "test.mp3"

Write-Host "✅ TTS Connection successful!" -ForegroundColor Green
```

---

## 🎙️ Step 2: Generate Audio MP3s from Markdown

### 2.1 PowerShell Script: Convert Markdown to Audio

Save as: `c:\SupportServices\AzureDevOpsSelflearn\Generate-Audio.ps1`

```powershell
# ============================================================================
# Generate-Audio.ps1
# Converts all markdown documents to MP3 files using Azure TTS (Free Tier)
# ============================================================================

param(
    [string]$TtsKey = $env:AZURE_TTS_KEY,
    [string]$TtsRegion = "eastus",
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio"
)

# Create output directory
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Validate TTS credentials
if (!$TtsKey) {
    Write-Error "TTS Key not provided. Set env variable: AZURE_TTS_KEY"
    exit 1
}

$ttsEndpoint = "https://$TtsRegion.tts.speech.microsoft.com/cognitiveservices/v1"
$headers = @{
    "Ocp-Apim-Subscription-Key" = $TtsKey
    "Content-Type" = "application/ssml+xml"
    "X-Microsoft-OutputFormat" = "audio-16khz-32kbitrate-mono-mp3"
}

# Get all markdown files (excluding README)
$mdFiles = Get-ChildItem -Path $DocsFolder -Filter "*.md" | 
    Where-Object { $_.Name -notlike "README.md" } |
    Sort-Object Name

Write-Host "Found $($mdFiles.Count) documents to convert" -ForegroundColor Cyan

$totalChars = 0

foreach ($file in $mdFiles) {
    $mdContent = Get-Content -Path $file.FullName -Raw
    
    # Remove markdown syntax (keep only text content)
    $cleanText = $mdContent `
        -replace '```[\s\S]*?```', '' `
        -replace '#+ ', '' `
        -replace '\*\*', '' `
        -replace '__', '' `
        -replace '\[([^\]]+)\]\([^\)]+\)', '$1' `
        -replace '`', '' `
        -replace '!\[.*?\]\(.*?\)', '' `
        -replace '---', '' `
        -replace '|\s+', ' ' `
        -replace '\s+', ' '
    
    $charCount = $cleanText.Length
    $totalChars += $charCount
    
    # Create SSML (Speech Synthesis Markup Language)
    # Use different voices for variety
    $voice = if ($totalChars % 2 -eq 0) { "en-US-AriaNeural" } else { "en-US-GuyNeural" }
    
    $ssml = @"
<speak version='1.0' xml:lang='en-US'>
    <voice name='$voice'>
        <prosody rate='0.95' pitch='0%'>
            $([System.Security.SecurityElement]::Escape($cleanText))
        </prosody>
    </voice>
</speak>
"@
    
    $outputFile = Join-Path $OutputFolder "$($file.BaseName).mp3"
    
    try {
        Write-Host "Converting: $($file.Name) ($charCount chars)..." -ForegroundColor Yellow
        
        $response = Invoke-WebRequest -Uri $ttsEndpoint `
            -Headers $headers `
            -Body $ssml `
            -Method Post `
            -OutFile $outputFile `
            -PassThru
        
        if ($response.StatusCode -eq 200) {
            $fileSizeKB = (Get-Item $outputFile).Length / 1KB
            Write-Host "  ✅ Generated: $($file.Name) → $(Split-Path -Leaf $outputFile) ($([math]::Round($fileSizeKB))KB)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Add small delay to avoid rate limiting
    Start-Sleep -Milliseconds 500
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "Total characters processed: $totalChars" -ForegroundColor White
Write-Host "Free tier limit: 500,000 chars/month" -ForegroundColor White
Write-Host "Usage: $(($totalChars / 500000 * 100).ToString('F1'))% of monthly limit" -ForegroundColor White
Write-Host "`n✅ Audio files saved to: $OutputFolder" -ForegroundColor Green
```

### 2.2 Run Audio Generation

```powershell
# Set your Azure TTS key as environment variable
$env:AZURE_TTS_KEY = "YOUR_KEY_HERE"

# Run the script
& "c:\SupportServices\AzureDevOpsSelflearn\Generate-Audio.ps1"

# Check output
Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\audio" -Filter "*.mp3"
```

**Expected Output:**
```
✅ 01-Git-Workflow-Branching.mp3 (8.2MB, ~15 min)
✅ 02-CI-CD-Pipelines.mp3 (6.5MB, ~12 min)
✅ 03-Infrastructure-as-Code-Bicep.mp3 (6.1MB, ~11 min)
... (11 total files)
```

---

## 🎬 Step 3: Create Video Slides from Markdown

### 3.1 PowerShell Script: Generate Slide Images

Save as: `c:\SupportServices\AzureDevOpsSelflearn\Generate-Slides.ps1`

```powershell
# ============================================================================
# Generate-Slides.ps1
# Creates slide images from markdown documents
# ============================================================================

param(
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides"
)

# Create output directory
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Function to extract slides from markdown
function Extract-Slides {
    param([string]$Content)
    
    # Split by sections (## heading)
    $sections = $Content -split '(?=^## )' | Where-Object { $_.Trim() }
    
    $slides = @()
    foreach ($section in $sections) {
        $lines = $section.Split("`n") | Where-Object { $_.Trim() }
        
        if ($lines.Count -gt 0) {
            # First line is title
            $title = $lines[0] -replace '^#+\s+', ''
            
            # Rest is content
            $content = ($lines | Select-Object -Skip 1 | Select-Object -First 5) -join "`n"
            
            $slides += @{
                Title = $title
                Content = $content
            }
        }
    }
    
    return $slides
}

# Get markdown files
$mdFiles = Get-ChildItem -Path $DocsFolder -Filter "*.md" | 
    Where-Object { $_.Name -notlike "README.md" } |
    Sort-Object Name

foreach ($file in $mdFiles) {
    $mdContent = Get-Content -Path $file.FullName -Raw
    $slides = Extract-Slides -Content $mdContent
    
    $docFolder = Join-Path $OutputFolder $file.BaseName
    if (!(Test-Path $docFolder)) {
        New-Item -ItemType Directory -Path $docFolder -Force | Out-Null
    }
    
    # Create title slide
    $titleContent = @"
$($file.BaseName)
Interview-Ready & Learning Guide

$(Get-Date -Format "yyyy-MM-dd")
"@
    
    Create-TextSlide -Text $titleContent `
        -OutputPath (Join-Path $docFolder "slide_00_title.png") `
        -BackgroundColor "#1e3a8a"
    
    # Create content slides
    for ($i = 0; $i -lt $slides.Count; $i++) {
        $slideText = "$($slides[$i].Title)`n`n$($slides[$i].Content)"
        
        Create-TextSlide -Text $slideText `
            -OutputPath (Join-Path $docFolder "slide_$(($i+1).ToString('00'))_content.png") `
            -BackgroundColor "#0f172a"
    }
    
    Write-Host "✅ Generated $(($slides.Count + 1)) slides for: $($file.Name)" -ForegroundColor Green
}

function Create-TextSlide {
    param(
        [string]$Text,
        [string]$OutputPath,
        [string]$BackgroundColor = "#1e3a8a"
    )
    
    # Using ImageMagick (convert command)
    # You'll need to install: choco install imagemagick
    
    $convertCmd = "convert"
    
    # Check if ImageMagick is available
    $im = Get-Command magick -ErrorAction SilentlyContinue
    if (!$im) {
        $im = Get-Command convert -ErrorAction SilentlyContinue
    }
    
    if (!$im) {
        Write-Warning "ImageMagick not installed. Skipping slide generation."
        return
    }
    
    # Create slide using ImageMagick
    & magick `
        -size 1920x1080 `
        "xc:$BackgroundColor" `
        -font Arial `
        -pointsize 48 `
        -fill white `
        -gravity Center `
        -annotate +0+0 "$Text" `
        "$OutputPath"
}

Write-Host "`n✅ Slides generated in: $OutputFolder" -ForegroundColor Green
```

### 3.2 Install ImageMagick (For Slide Generation)

```powershell
# Using Chocolatey
choco install imagemagick -y

# Or download from: https://imagemagick.org/script/download.php
```

---

## 🎥 Step 4: Create Videos (Audio + Slides with FFmpeg)

### 4.1 PowerShell Script: Generate Videos

Save as: `c:\SupportServices\AzureDevOpsSelflearn\Generate-Videos.ps1`

```powershell
# ============================================================================
# Generate-Videos.ps1
# Creates video files by combining slides + audio using FFmpeg
# ============================================================================

param(
    [string]$AudioFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio",
    [string]$SlidesFolder = "c:\SupportServices\AzureDevOpsSelflearn\slides",
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\videos",
    [int]$SlideShowDurationSeconds = 3  # How long each slide appears
)

# Create output directory
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Check FFmpeg availability
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (!$ffmpeg) {
    Write-Error "FFmpeg not found. Install with: choco install ffmpeg"
    exit 1
}

# Get audio files
$audioFiles = Get-ChildItem -Path $AudioFolder -Filter "*.mp3" | Sort-Object Name

foreach ($audioFile in $audioFiles) {
    $docName = $audioFile.BaseName
    $slidesDir = Join-Path $SlidesFolder $docName
    $outputVideo = Join-Path $OutputFolder "$docName.mp4"
    
    if (!(Test-Path $slidesDir)) {
        Write-Warning "Slides folder not found: $slidesDir"
        continue
    }
    
    Write-Host "Creating video for: $docName..." -ForegroundColor Cyan
    
    # Get all slides for this document
    $slides = Get-ChildItem -Path $slidesDir -Filter "slide_*.png" | Sort-Object Name
    
    if ($slides.Count -eq 0) {
        Write-Warning "No slides found for $docName"
        continue
    }
    
    # Get audio duration
    $ffprobeCmd = @"
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1:noinvert_equals=1 "$($audioFile.FullName)"
"@
    
    $audioDuration = [int](Invoke-Expression $ffprobeCmd)
    $slidesPerSecond = [math]::Max(1, $slides.Count / $audioDuration)
    
    Write-Host "  Audio duration: $audioDuration seconds"
    Write-Host "  Slides: $($slides.Count)"
    Write-Host "  Duration per slide: $([math]::Round(1/$slidesPerSecond, 2)) seconds"
    
    # Create video using FFmpeg
    # Concatenate slides with crossfade transition
    
    $concatFile = Join-Path $slidesDir "concat.txt"
    
    # Create concat demuxer file
    $concatContent = ""
    foreach ($slide in $slides) {
        $concatContent += "file '$($slide.FullName)'`noutpoint $($SlideShowDurationSeconds)`n"
    }
    
    Set-Content -Path $concatFile -Value $concatContent
    
    # Create video
    $ffmpegArgs = @(
        "-f", "concat"
        "-safe", "0"
        "-i", "`"$concatFile`""
        "-i", "`"$($audioFile.FullName)`""
        "-c:v", "libx264"
        "-preset", "fast"
        "-pix_fmt", "yuv420p"
        "-c:a", "aac"
        "-shortest"
        "-y"
        "`"$outputVideo`""
    )
    
    Write-Host "  Running FFmpeg..." -ForegroundColor Yellow
    
    try {
        & ffmpeg $ffmpegArgs 2>&1 | ForEach-Object {
            if ($_ -match "progress=" -or $_ -match "time=") {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
        
        if (Test-Path $outputVideo) {
            $videoSize = (Get-Item $outputVideo).Length / 1MB
            Write-Host "  ✅ Video created: $docName.mp4 ($([math]::Round($videoSize, 1))MB)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ❌ Error creating video: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Clean up concat file
    Remove-Item -Path $concatFile -Force -ErrorAction SilentlyContinue
}

Write-Host "`n✅ Videos generated in: $OutputFolder" -ForegroundColor Green
```

### 4.2 Run Video Generation

```powershell
# Install FFmpeg first (if not already installed)
choco install ffmpeg -y

# Generate slides
& "c:\SupportServices\AzureDevOpsSelflearn\Generate-Slides.ps1"

# Generate videos
& "c:\SupportServices\AzureDevOpsSelflearn\Generate-Videos.ps1"

# Check output
Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\videos" -Filter "*.mp4"
```

---

## ☁️ Step 5: Upload to Azure Blob Storage (Free)

### 5.1 Create Storage Account

```powershell
# Login to Azure
Connect-AzAccount

# Create resource group
$resourceGroup = "rg-training-free"
$location = "eastus"

New-AzResourceGroup -Name $resourceGroup -Location $location

# Create storage account (free tier available)
$storageAccount = New-AzStorageAccount `
    -ResourceGroupName $resourceGroup `
    -Name "trainingmedia$(Get-Random)" `
    -SkuName "Standard_LRS" `
    -Location $location `
    -Kind "StorageV2"

# Get storage context
$ctx = $storageAccount.Context
```

### 5.2 Create Containers & Upload Files

```powershell
# Create containers
New-AzStorageContainer -Name "audio" -Context $ctx -Permission "Public"
New-AzStorageContainer -Name "videos" -Context $ctx -Permission "Public"
New-AzStorageContainer -Name "slides" -Context $ctx -Permission "Public"

# Upload audio files
$audioFiles = Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\audio" -Filter "*.mp3"
foreach ($file in $audioFiles) {
    Set-AzStorageBlobContent -File $file.FullName `
        -Container "audio" `
        -Blob $file.Name `
        -Context $ctx
    Write-Host "✅ Uploaded: $($file.Name)"
}

# Upload videos
$videoFiles = Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\videos" -Filter "*.mp4"
foreach ($file in $videoFiles) {
    Set-AzStorageBlobContent -File $file.FullName `
        -Container "videos" `
        -Blob $file.Name `
        -Context $ctx
    Write-Host "✅ Uploaded: $($file.Name)"
}

# Get public URLs
$audioUrl = "$($ctx.BlobEndPoint)audio/"
$videosUrl = "$($ctx.BlobEndPoint)videos/"

Write-Host "`n🎙️  Audio files: $audioUrl" -ForegroundColor Green
Write-Host "🎥 Video files: $videosUrl" -ForegroundColor Green
```

---

## 📋 Complete Automation Script (All-in-One)

Save as: `c:\SupportServices\AzureDevOpsSelflearn\Run-All.ps1`

```powershell
# ============================================================================
# Run-All.ps1
# Complete automation: Audio + Video + Upload to Azure (All Free)
# ============================================================================

param(
    [string]$TtsKey = $env:AZURE_TTS_KEY,
    [string]$TtsRegion = "eastus"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "🚀 Azure DevOps Training: Audio & Video Generation" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

# Step 1: Validate prerequisites
Write-Host "1️⃣  Checking prerequisites..." -ForegroundColor Yellow
$prereqsOK = $true

if (!$TtsKey) {
    Write-Host "  ❌ Azure TTS Key not set. Set: `$env:AZURE_TTS_KEY" -ForegroundColor Red
    $prereqsOK = $false
}

if (!(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "  ❌ FFmpeg not installed. Run: choco install ffmpeg" -ForegroundColor Red
    $prereqsOK = $false
}

if (!(Get-Command magick -ErrorAction SilentlyContinue) -and !(Get-Command convert -ErrorAction SilentlyContinue)) {
    Write-Host "  ❌ ImageMagick not installed. Run: choco install imagemagick" -ForegroundColor Red
    $prereqsOK = $false
}

if (!$prereqsOK) {
    Write-Host "`n❌ Please install missing prerequisites and try again" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ All prerequisites found`n" -ForegroundColor Green

# Step 2: Generate audio
Write-Host "2️⃣  Generating audio files from markdown..." -ForegroundColor Yellow
& "$scriptDir\Generate-Audio.ps1" -TtsKey $TtsKey -TtsRegion $TtsRegion
Write-Host ""

# Step 3: Generate slides
Write-Host "3️⃣  Generating slide images..." -ForegroundColor Yellow
& "$scriptDir\Generate-Slides.ps1"
Write-Host ""

# Step 4: Generate videos
Write-Host "4️⃣  Creating videos (audio + slides)..." -ForegroundColor Yellow
Write-Host "  (This may take 10-15 minutes...)" -ForegroundColor Gray
& "$scriptDir\Generate-Videos.ps1"
Write-Host ""

# Step 5: Summary
Write-Host "5️⃣  Summary of generated files:" -ForegroundColor Yellow
Write-Host "`n  🎙️  Audio files:" -ForegroundColor Cyan
Get-ChildItem "$scriptDir\audio" -Filter "*.mp3" | ForEach-Object {
    $sizeMB = $_.Length / 1MB
    Write-Host "    ✅ $($_.Name) ($([math]::Round($sizeMB, 1))MB)"
}

Write-Host "`n  🎥 Video files:" -ForegroundColor Cyan
Get-ChildItem "$scriptDir\videos" -Filter "*.mp4" | ForEach-Object {
    $sizeMB = $_.Length / 1MB
    Write-Host "    ✅ $($_.Name) ($([math]::Round($sizeMB, 1))MB)"
}

Write-Host "`n✅ Generation complete!" -ForegroundColor Green
Write-Host "`n📁 Files located at:" -ForegroundColor Cyan
Write-Host "  Audio: $scriptDir\audio" -ForegroundColor White
Write-Host "  Videos: $scriptDir\videos" -ForegroundColor White

Write-Host "`n📤 Next: Upload to Azure Storage (free tier)" -ForegroundColor Yellow
Write-Host "  Run: .\Upload-To-Azure.ps1 -AudioFolder '$scriptDir\audio' -VideoFolder '$scriptDir\videos'" -ForegroundColor Gray
```

---

## 🎙️ Quick Start (3 Commands)

```powershell
# 1. Install prerequisites (one-time)
choco install ffmpeg imagemagick powershell-core -y

# 2. Set Azure TTS key
$env:AZURE_TTS_KEY = "YOUR_AZURE_TTS_KEY_HERE"

# 3. Run complete automation
& "c:\SupportServices\AzureDevOpsSelflearn\Run-All.ps1"
```

---

## 📊 Expected Results

### Audio Output
```
✅ 01-Git-Workflow-Branching.mp3 (8.2MB, 15:30 minutes)
✅ 02-CI-CD-Pipelines.mp3 (6.5MB, 12:15 minutes)
✅ 03-Infrastructure-as-Code-Bicep.mp3 (6.1MB, 11:45 minutes)
✅ 04-Testing-Strategy.mp3 (5.8MB, 11:00 minutes)
✅ 05-Blue-Green-Deployment.mp3 (5.4MB, 10:30 minutes)
✅ 06-Troubleshooting-Recovery.mp3 (6.2MB, 12:00 minutes)
✅ 07-DevOps-Concepts.mp3 (6.8MB, 13:15 minutes)
✅ 08-Cost-Optimization.mp3 (5.9MB, 11:30 minutes)
✅ 09-YAML-Configuration.mp3 (6.1MB, 11:45 minutes)
✅ 10-OneBranch-vs-Other-Tools.mp3 (6.4MB, 12:30 minutes)
✅ 11-Containers-Orchestration.mp3 (6.2MB, 12:00 minutes)

Total: ~130 minutes of audio content (~65MB)
Azure TTS Free Tier: ✅ 500,000 chars/month (using ~70,000)
```

### Video Output
```
✅ 01-Git-Workflow-Branching.mp4 (450MB, 15:30 min @ 1080p)
✅ 02-CI-CD-Pipelines.mp4 (380MB, 12:15 min @ 1080p)
... (11 total videos)

Total: ~4-5GB of video content
Recommended: Host on Azure Blob Storage (5GB free tier)
```

---

## 💾 Cost Analysis

| Service | Usage | Free Tier | Cost |
|---------|-------|-----------|------|
| **Text-to-Speech** | ~70K chars | 500K/month ✅ | Free |
| **Blob Storage** | ~5GB | 5GB/year ✅ | Free |
| **Data Transfer** | Egress | First 100GB/month ✅ | Free |
| **FFmpeg** | Video encoding | Open source ✅ | Free |
| **Total** | | | **$0** |

**All tools and services used are completely free!**

---

## 🎯 Final Hosting Options (Free)

### Option 1: Azure Static Web Apps (Free)
Create an index page with video/audio player:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Azure DevOps Training</title>
</head>
<body>
    <h1>🚀 Azure DevOps Self-Learning Library</h1>
    
    <h2>🎙️ Audio Lessons</h2>
    <ul>
        <li><a href="https://your-storage.blob.core.windows.net/audio/01-Git-Workflow-Branching.mp3">Git Workflow & Branching</a></li>
        <!-- More audio links -->
    </ul>
    
    <h2>🎥 Video Lessons</h2>
    <ul>
        <li>
            <video width="640" height="360" controls>
                <source src="https://your-storage.blob.core.windows.net/videos/01-Git-Workflow-Branching.mp4" type="video/mp4">
            </video>
        </li>
        <!-- More video embeds -->
    </ul>
</body>
</html>
```

### Option 2: GitHub Pages (Free)
Upload files and create a simple website.

### Option 3: Azure Blob Storage Direct Links
Share audio/video URLs directly:
```
https://trainingmedia123.blob.core.windows.net/audio/01-Git-Workflow-Branching.mp3
https://trainingmedia123.blob.core.windows.net/videos/01-Git-Workflow-Branching.mp4
```

---

## ✅ Checklist

- [ ] Create Azure Cognitive Services account (free tier)
- [ ] Get Text-to-Speech key and endpoint
- [ ] Install FFmpeg and ImageMagick
- [ ] Set Azure TTS key environment variable
- [ ] Run `Run-All.ps1` script
- [ ] Verify audio files in `./audio` folder
- [ ] Verify video files in `./videos` folder
- [ ] Create Azure Storage account (free tier)
- [ ] Upload audio and video to Blob Storage
- [ ] Create hosting page (Static Web Apps or GitHub Pages)
- [ ] Share training link with team

**Total time: ~30 minutes (setup) + 20-30 minutes (generation) = 1 hour**

