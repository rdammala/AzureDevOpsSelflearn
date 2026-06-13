#!/usr/bin/env pwsh
# ============================================================================
# Generate-Audio.ps1
# Convert all markdown documents to MP3 files using Azure TTS (Free Tier)
# ============================================================================
# Usage: ./Generate-Audio.ps1 -TtsKey "your-key" -TtsRegion "eastus"
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$TtsKey = $env:AZURE_TTS_KEY,
    
    [Parameter(Mandatory=$false)]
    [string]$TtsRegion = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsFolder = "c:\SupportServices\AzureDevOpsSelflearn",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\SupportServices\AzureDevOpsSelflearn\audio"
)

# ============================================================================
# VALIDATION
# ============================================================================

if (!$TtsKey) {
    Write-Host "❌ Error: Azure TTS Key not provided" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set the key using:"
    Write-Host '  $env:AZURE_TTS_KEY = "your-key-here"' -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or run:"
    Write-Host '  ./Generate-Audio.ps1 -TtsKey "your-key-here"' -ForegroundColor Yellow
    exit 1
}

if (!(Test-Path $DocsFolder)) {
    Write-Host "❌ Docs folder not found: $DocsFolder" -ForegroundColor Red
    exit 1
}

# ============================================================================
# SETUP
# ============================================================================

# Create output directory
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "✅ Created output folder: $OutputFolder" -ForegroundColor Green
}

$ttsEndpoint = "https://$TtsRegion.tts.speech.microsoft.com/cognitiveservices/v1"

$headers = @{
    "Ocp-Apim-Subscription-Key" = $TtsKey
    "Content-Type" = "application/ssml+xml"
    "X-Microsoft-OutputFormat" = "audio-16khz-32kbitrate-mono-mp3"
}

# Test connection
Write-Host "🔗 Testing Azure TTS connection..." -ForegroundColor Cyan
try {
    $testSsml = @"
<speak version='1.0' xml:lang='en-US'>
    <voice name='en-US-AriaNeural'>
        Test connection
    </voice>
</speak>
"@
    
    $response = Invoke-WebRequest -Uri $ttsEndpoint `
        -Headers $headers `
        -Body $testSsml `
        -Method Post `
        -ErrorAction Stop
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Connection successful" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Check your TTS key and region" -ForegroundColor Yellow
    exit 1
}

# ============================================================================
# EXTRACT AND CLEAN TEXT
# ============================================================================

function Clean-MarkdownText {
    param([string]$Content)
    
    # Remove code blocks
    $content = $content -replace '```[\s\S]*?```', ''
    
    # Remove markdown headers
    $content = $content -replace '#+\s+', ''
    
    # Remove bold/italic
    $content = $content -replace '\*\*', ''
    $content = $content -replace '__', ''
    $content = $content -replace '\*', ''
    $content = $content -replace '_', ''
    
    # Remove inline code
    $content = $content -replace '`([^`]*)`', '$1'
    
    # Remove links
    $content = $content -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    
    # Remove images
    $content = $content -replace '!\[.*?\]\(.*?\)', ''
    
    # Remove horizontal rules
    $content = $content -replace '---+', ''
    
    # Remove extra whitespace
    $content = $content -replace '\s+', ' '
    
    # Remove table formatting
    $content = $content -replace '\|', ' '
    
    return $content.Trim()
}

# ============================================================================
# PROCESS DOCUMENTS
# ============================================================================

$mdFiles = Get-ChildItem -Path $DocsFolder -Filter "*.md" | 
    Where-Object { $_.Name -notlike "README.md" -and $_.Name -notlike "GENERATE*" } |
    Sort-Object Name

$totalChars = 0
$processedFiles = 0
$errorCount = 0

Write-Host "`n📄 Processing documents:" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

foreach ($file in $mdFiles) {
    $mdContent = Get-Content -Path $file.FullName -Raw
    $cleanText = Clean-MarkdownText -Content $mdContent
    
    $charCount = $cleanText.Length
    $totalChars += $charCount
    
    # Alternate between voices for variety
    $voice = if ($processedFiles % 2 -eq 0) { 
        "en-US-AriaNeural"  # Female voice
    } else { 
        "en-US-GuyNeural"   # Male voice
    }
    
    # Create SSML with better formatting
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
    
    # Check if already exists
    if (Test-Path $outputFile) {
        Write-Host "⏭️  Skipping (exists): $($file.Name)" -ForegroundColor Gray
        $processedFiles++
        continue
    }
    
    Write-Host "🔄 Converting: $($file.Name)" -ForegroundColor Yellow
    Write-Host "   Voice: $voice | Characters: $charCount" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $ttsEndpoint `
            -Headers $headers `
            -Body $ssml `
            -Method Post `
            -OutFile $outputFile `
            -PassThru `
            -ErrorAction Stop
        
        if ($response.StatusCode -eq 200 -and (Test-Path $outputFile)) {
            $fileSizeKB = (Get-Item $outputFile).Length / 1KB
            $fileSizeMB = $fileSizeKB / 1024
            
            Write-Host "   ✅ Generated: $(Split-Path -Leaf $outputFile)" -ForegroundColor Green
            Write-Host "   📊 Size: $([math]::Round($fileSizeMB, 1))MB ($([math]::Round($fileSizeKB))KB)" -ForegroundColor Green
            
            $processedFiles++
        }
        else {
            Write-Host "   ❌ Failed to save file" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    # Add delay to avoid rate limiting (500ms between requests)
    if ($processedFiles -lt $mdFiles.Count) {
        Start-Sleep -Milliseconds 500
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n📊 SUMMARY" -ForegroundColor Cyan
Write-Host "==========" -ForegroundColor Cyan
Write-Host "Documents processed: $processedFiles/$($mdFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "📈 Azure TTS Free Tier Usage:" -ForegroundColor Cyan
Write-Host "  Characters processed: $totalChars" -ForegroundColor White
Write-Host "  Free tier limit: 500,000 chars/month" -ForegroundColor White
Write-Host "  Usage percentage: $(($totalChars / 500000 * 100).ToString('F2'))%" -ForegroundColor White
Write-Host ""
Write-Host "📁 Output folder: $OutputFolder" -ForegroundColor Green

# List generated files
$audioFiles = Get-ChildItem -Path $OutputFolder -Filter "*.mp3"
if ($audioFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ Generated audio files:" -ForegroundColor Green
    foreach ($audio in $audioFiles | Sort-Object Name) {
        $sizeMB = $audio.Length / 1MB
        Write-Host "  🎙️  $($audio.Name) ($([math]::Round($sizeMB, 1))MB)" -ForegroundColor White
    }
}

if ($errorCount -eq 0) {
    Write-Host "`n✅ All files generated successfully!" -ForegroundColor Green
}
else {
    Write-Host "`n⚠️  Some files failed. Check errors above." -ForegroundColor Yellow
}
