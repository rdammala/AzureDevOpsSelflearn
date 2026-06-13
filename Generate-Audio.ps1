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
    Write-Host "[ERROR] Azure TTS Key not provided" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set the key using:" -ForegroundColor Yellow
    Write-Host '  $env:AZURE_TTS_KEY = "your-key-here"' -ForegroundColor Gray
    exit 1
}

if (!(Test-Path $DocsFolder)) {
    Write-Host "[ERROR] Docs folder not found: $DocsFolder" -ForegroundColor Red
    exit 1
}

# Create output directory
if (!(Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "[OK] Created output folder: $OutputFolder" -ForegroundColor Green
}

$ttsEndpoint = "https://$TtsRegion.tts.speech.microsoft.com/cognitiveservices/v1"

$headers = @{
    "Ocp-Apim-Subscription-Key" = $TtsKey
    "Content-Type" = "application/ssml+xml"
    "X-Microsoft-OutputFormat" = "audio-16khz-32kbitrate-mono-mp3"
}

# Test connection
Write-Host "[INFO] Testing Azure TTS connection..." -ForegroundColor Cyan
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
        Write-Host "[OK] Connection successful" -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ============================================================================
# EXTRACT AND CLEAN TEXT
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
    $content = $content -replace '\s+', ' '
    $content = $content -replace '\|', ' '
    
    return $content.Trim()
}

# ============================================================================
# CREATE NATURAL SSML WITH PROSODY VARIATION
# ============================================================================

function Create-NaturalSSML {
    param(
        [string]$Text,
        [string]$VoiceName
    )
    
    # Split into paragraphs
    $paragraphs = $Text -split "\.{2,}|\n{2,}" | Where-Object { $_.Trim().Length -gt 0 }
    
    $ssmlContent = ""
    $sentenceCount = 0
    
    foreach ($paragraph in $paragraphs) {
        # Add paragraph break
        if ($ssmlContent.Length -gt 0) {
            $ssmlContent += '<break time="500ms" />'
        }
        
        # Split into sentences
        $sentences = $paragraph -split '(?<=[.!?])\s+' | Where-Object { $_.Trim().Length -gt 0 }
        
        foreach ($sentence in $sentences) {
            $trimmed = $sentence.Trim()
            if ($trimmed.Length -eq 0) { continue }
            
            $sentenceCount++
            
            # Vary prosody based on sentence position (creates natural rhythm)
            $rate = @(0.98, 1.02, 1.00, 0.97)[($sentenceCount - 1) % 4]
            $pitch = @(0, 2, -1, 1)[($sentenceCount - 1) % 4]
            $volume = @(100, 105, 95, 100)[($sentenceCount - 1) % 4]
            
            # Add emphasis to sentences with key words
            $emphasized = $trimmed
            $emphasized = $emphasized -replace '(critical|important|key|essential|must|required|must-have)', '<emphasis level="strong">$1</emphasis>'
            $emphasized = $emphasized -replace '(however|therefore|moreover|furthermore)', '<emphasis level="moderate">$1</emphasis>'
            
            # Add the sentence with prosody
            $ssmlContent += "<prosody rate='$rate' pitch='${pitch}%' volume='$volume'>"
            $ssmlContent += [System.Security.SecurityElement]::Escape($emphasized)
            $ssmlContent += "</prosody>"
            
            # Add slight break between sentences
            $ssmlContent += '<break time="200ms" />'
        }
    }
    
    $ssml = @"
<speak version='1.0' xml:lang='en-US'>
    <voice name='$VoiceName'>
        $ssmlContent
    </voice>
</speak>
"@
    
    return $ssml
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

Write-Host ""
Write-Host "Processing documents:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $mdFiles) {
    $mdContent = Get-Content -Path $file.FullName -Raw
    $cleanText = Clean-MarkdownText -Content $mdContent
    
    $charCount = $cleanText.Length
    $totalChars += $charCount
    
    $voice = if ($processedFiles % 2 -eq 0) { 
        "en-US-AriaNeural"
    } else { 
        "en-US-GuyNeural"
    }
    
    $ssml = Create-NaturalSSML -Text $cleanText -VoiceName $voice
    
    $outputFile = Join-Path $OutputFolder "$($file.BaseName).mp3"
    
    if (Test-Path $outputFile) {
        Write-Host "[SKIP] Already exists: $($file.Name)" -ForegroundColor Gray
        $processedFiles++
        continue
    }
    
    Write-Host "[INFO] Converting: $($file.Name)" -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $ttsEndpoint `
            -Headers $headers `
            -Body $ssml `
            -Method Post `
            -OutFile $outputFile `
            -PassThru `
            -ErrorAction Stop
        
        if ($response.StatusCode -eq 200 -and (Test-Path $outputFile)) {
            $sizeMB = (Get-Item $outputFile).Length / 1MB
            Write-Host "[OK] Generated: $($file.BaseName).mp3 ($([math]::Round($sizeMB, 1))MB)" -ForegroundColor Green
            $processedFiles++
        }
        else {
            Write-Host "[ERROR] Failed to save file" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    if ($processedFiles -lt $mdFiles.Count) {
        Start-Sleep -Milliseconds 500
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Documents processed: $processedFiles/$($mdFiles.Count)" -ForegroundColor White
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "Azure TTS Usage:" -ForegroundColor Cyan
Write-Host "  Characters: $totalChars / 500,000" -ForegroundColor White
Write-Host "  Percentage: $(($totalChars / 500000 * 100).ToString('F2'))%" -ForegroundColor White
Write-Host ""
Write-Host "[SUCCESS] Audio generation complete!" -ForegroundColor Green
