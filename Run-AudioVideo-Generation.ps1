#!/usr/bin/env pwsh
# ============================================================================
# Run-AudioVideo-Generation.ps1
# Complete automation: Generate audio + video from markdown (All Free)
# ============================================================================
# Usage: ./Run-AudioVideo-Generation.ps1 -TtsKey "your-azure-key"
# ============================================================================

param(
    [Parameter(Mandatory=$true, HelpMessage="Azure Cognitive Services Text-to-Speech Key")]
    [string]$TtsKey,
    
    [Parameter(Mandatory=$false)]
    [string]$TtsRegion = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$BaseFolder = "c:\SupportServices\AzureDevOpsSelflearn"
)

$ErrorActionPreference = "Continue"

# ============================================================================
# BANNER
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "================================================================================"
Write-Host ""
Write-Host "   AZURE DEVOPS SELF-LEARNING LIBRARY"
Write-Host "   Audio & Video Generation (Free Tier)"
Write-Host ""
Write-Host "   Using:"
Write-Host "   - Azure Text-to-Speech (Free: 500K chars/month)"
Write-Host "   - FFmpeg (Open Source)"
Write-Host "   - Azure Blob Storage (Free: 5GB)"
Write-Host ""
Write-Host "================================================================================"
Write-Host ""

# ============================================================================
# PHASE 1: VALIDATE PREREQUISITES
# ============================================================================

Write-Host "[1] PHASE 1: Validating Prerequisites" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor Cyan

$prereqFailed = $false

# Check Azure TTS Key
if ([string]::IsNullOrWhiteSpace($TtsKey)) {
    Write-Host "[X] Error: Azure TTS Key is required" -ForegroundColor Red
    Write-Host "    Use: ./Run-AudioVideo-Generation.ps1 -TtsKey 'your-key'" -ForegroundColor Yellow
    $prereqFailed = $true
}
else {
    Write-Host "[OK] Azure TTS Key provided" -ForegroundColor Green
}

# Check FFmpeg
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpeg) {
    Write-Host "[OK] FFmpeg found" -ForegroundColor Green
}
else {
    Write-Host "[X] FFmpeg not installed" -ForegroundColor Red
    Write-Host "    Install: choco install ffmpeg -y" -ForegroundColor Yellow
    $prereqFailed = $true
}

# Check base folder
if (Test-Path $BaseFolder) {
    Write-Host "[OK] Base folder found: $BaseFolder" -ForegroundColor Green
}
else {
    Write-Host "[X] Base folder not found: $BaseFolder" -ForegroundColor Red
    $prereqFailed = $true
}

# Check markdown files
$mdFiles = @(Get-ChildItem -Path $BaseFolder -Filter "*.md" -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -notlike "README.md" -and $_.Name -notlike "GENERATE*" })

if ($mdFiles.Count -gt 0) {
    Write-Host "[OK] Found $($mdFiles.Count) markdown files" -ForegroundColor Green
}
else {
    Write-Host "[X] No markdown files found in: $BaseFolder" -ForegroundColor Red
    $prereqFailed = $true
}

if ($prereqFailed) {
    Write-Host "`n[X] Prerequisites not met. Please fix issues above and try again." -ForegroundColor Red
    exit 1
}

Write-Host "`n[OK] All prerequisites validated`n" -ForegroundColor Green

# ============================================================================
# PHASE 2: TEST AZURE TTS CONNECTION
# ============================================================================

Write-Host "[2] PHASE 2: Testing Azure TTS Connection" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$ttsEndpoint = "https://$TtsRegion.tts.speech.microsoft.com/cognitiveservices/v1"

$headers = @{
    "Ocp-Apim-Subscription-Key" = $TtsKey
    "Content-Type" = "application/ssml+xml"
    "X-Microsoft-OutputFormat" = "audio-16khz-32kbitrate-mono-mp3"
}

try {
    $testSsml = @"
<speak version='1.0' xml:lang='en-US'>
    <voice name='en-US-AriaNeural'>
        Testing connection to Azure Text to Speech
    </voice>
</speak>
"@
    
    $testFile = Join-Path $env:TEMP "tts_test_$(Get-Random).mp3"
    
    $response = Invoke-WebRequest -Uri $ttsEndpoint `
        -Headers $headers `
        -Body $testSsml `
        -Method Post `
        -OutFile $testFile `
        -TimeoutSec 30 `
        -ErrorAction Stop
    
    if ((Test-Path $testFile) -and (Get-Item $testFile).Length -gt 0) {
        Write-Host "[OK] Azure TTS connection successful" -ForegroundColor Green
        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Host "[X] Azure TTS returned empty response" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "[X] Azure TTS connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    Check your TTS key and region" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[OK] Connection test passed`n" -ForegroundColor Green

# ============================================================================
# PHASE 3: GENERATE AUDIO
# ============================================================================

Write-Host "[3] PHASE 3: Generating Audio Files (MP3)" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

$generateAudioScript = Join-Path $BaseFolder "Generate-Audio.ps1"

if (!(Test-Path $generateAudioScript)) {
    Write-Host "[X] Generate-Audio.ps1 not found at: $generateAudioScript" -ForegroundColor Red
    Write-Host "    Please ensure this file exists in the AzureDevOpsSelflearn folder" -ForegroundColor Yellow
    exit 1
}

try {
    & $generateAudioScript -TtsKey $TtsKey -TtsRegion $TtsRegion -DocsFolder $BaseFolder
}
catch {
    Write-Host "`n[X] Error during audio generation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$audioFolder = Join-Path $BaseFolder "audio"
$audioFiles = @(Get-ChildItem -Path $audioFolder -Filter "*.mp3" -ErrorAction SilentlyContinue)

if ($audioFiles.Count -eq 0) {
    Write-Host "[X] No audio files were generated" -ForegroundColor Red
    exit 1
}

Write-Host "`n[OK] Audio generation complete ($($audioFiles.Count) files)`n" -ForegroundColor Green

# ============================================================================
# PHASE 4: GENERATE VIDEOS
# ============================================================================

Write-Host "[4] PHASE 4: Generating Video Files (MP4)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$generateVideosScript = Join-Path $BaseFolder "Generate-Videos.ps1"

if (!(Test-Path $generateVideosScript)) {
    Write-Host "[!] Generate-Videos.ps1 not found. Skipping video generation." -ForegroundColor Yellow
    Write-Host "    You can run video generation later with: $generateVideosScript`n" -ForegroundColor Gray
}
else {
    try {
        & $generateVideosScript -AudioFolder $audioFolder
    }
    catch {
        Write-Host "[!] Error during video generation: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "    You can retry later with: $generateVideosScript`n" -ForegroundColor Gray
    }
}

$videoFolder = Join-Path $BaseFolder "videos"
$videoFiles = @(Get-ChildItem -Path $videoFolder -Filter "*.mp4" -ErrorAction SilentlyContinue)

if ($videoFiles.Count -gt 0) {
    Write-Host "[OK] Video generation complete ($($videoFiles.Count) files)`n" -ForegroundColor Green
}
else {
    Write-Host "[!] No video files were generated. This may require ImageMagick.`n" -ForegroundColor Yellow
}

# ============================================================================
# PHASE 5: SUMMARY & NEXT STEPS
# ============================================================================

Write-Host "[5] PHASE 5: Summary & Next Steps" -ForegroundColor Cyan
Write-Host "=================================`n" -ForegroundColor Cyan

Write-Host "Generated Files:" -ForegroundColor White
Write-Host "  Audio folder: $audioFolder" -ForegroundColor Gray
Write-Host "  Video folder: $videoFolder" -ForegroundColor Gray

Write-Host ""
Write-Host "File Summary:" -ForegroundColor White

$audioSize = 0
foreach ($audio in $audioFiles) {
    $audioSize += $audio.Length
}
Write-Host "  Audio files: $($audioFiles.Count) ($([math]::Round($audioSize / 1MB, 1))MB)" -ForegroundColor Gray

$videoSize = 0
foreach ($video in $videoFiles) {
    $videoSize += $video.Length
}
if ($videoFiles.Count -gt 0) {
    Write-Host "  Video files: $($videoFiles.Count) ($([math]::Round($videoSize / 1MB, 1))MB)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Azure TTS Usage:" -ForegroundColor White
$totalChars = 0
foreach ($md in $mdFiles) {
    $content = Get-Content -Path $md.FullName -Raw
    $totalChars += $content.Length
}
Write-Host "  Characters processed: $totalChars / 500,000" -ForegroundColor Gray
Write-Host "  Monthly usage: $(($totalChars / 500000 * 100).ToString('F2'))%" -ForegroundColor Gray

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. [DONE] Audio generation complete" -ForegroundColor White
Write-Host "     Share on Spotify, Apple Podcasts, or internal server" -ForegroundColor Gray
Write-Host ""

if ($videoFiles.Count -gt 0) {
    Write-Host "  2. [DONE] Video generation complete" -ForegroundColor White
    Write-Host "     Upload to YouTube, Azure Media Services, or LMS" -ForegroundColor Gray
}
else {
    Write-Host "  2. [PENDING] Generate videos (optional)" -ForegroundColor White
    Write-Host "     Install ImageMagick: choco install imagemagick -y" -ForegroundColor Gray
    Write-Host "     Run: $generateVideosScript" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  3. [NEXT] Upload to Azure (free tier)" -ForegroundColor White
Write-Host "     Create Azure Blob Storage account" -ForegroundColor Gray
Write-Host "     Upload audio and video files" -ForegroundColor Gray
Write-Host "     Share public URLs with team" -ForegroundColor Gray
Write-Host ""

Write-Host ""
Write-Host "================================================================================"
Write-Host "[SUCCESS] GENERATION COMPLETE!"
Write-Host "================================================================================"
Write-Host ""

# Show helpful commands
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # List audio files" -ForegroundColor Yellow
Write-Host "  Get-ChildItem '$audioFolder' -Filter '*.mp3'" -ForegroundColor Gray
Write-Host ""
Write-Host "  # List video files" -ForegroundColor Yellow
Write-Host "  Get-ChildItem '$videoFolder' -Filter '*.mp4'" -ForegroundColor Gray
Write-Host ""
Write-Host "  # Play audio file" -ForegroundColor Yellow
Write-Host "  & '$($audioFiles[0].FullName)'" -ForegroundColor Gray
Write-Host ""
