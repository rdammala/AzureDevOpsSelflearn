# Video Generation Summary

## Overview
This directory contains MP4 videos generated from the DevOps learning documents using Azure Cognitive Services Text-to-Speech and FFmpeg.

## What's Included
- **12 MP4 videos** - One per learning document
- **Simple slide format** - Each video loops a single title slide with narrated audio
- **Natural speech** - Generated with prosody variation (rate, pitch, volume)

## Video Files
1. `01-Git-Workflow-Branching.mp4` - Git branching strategies and workflows
2. `02-CI-CD-Pipelines.mp4` - CI/CD pipeline architecture and stages
3. `03-Infrastructure-as-Code-Bicep.mp4` - Bicep module structure and deployment
4. `04-Testing-Strategy.mp4` - Test categories and automation frameworks
5. `05-Blue-Green-Deployment.mp4` - Deployment patterns and traffic routing
6. `06-Troubleshooting-Recovery.mp4` - Incident response and recovery procedures
7. `07-DevOps-Concepts.mp4` - Core DevOps principles
8. `08-Cost-Optimization.mp4` - Cost monitoring and optimization
9. `09-YAML-Configuration.mp4` - YAML syntax and pipeline configuration
10. `10-OneBranch-vs-Other-Tools.mp4` - Microsoft build platform comparison
11. `11-Containers-Orchestration.mp4` - Container and Kubernetes concepts
12. `QUICK-START.md` - Video for quick reference guide

## Technical Details
- **Codec**: H.264 (libx264)
- **Resolution**: 1920x1080 (Full HD)
- **Audio**: AAC 192kbps
- **Format**: MP4 with AAC audio stream
- **Preset**: Ultrafast (balanced quality/speed)
- **CRF**: 28 (good quality for static images)

## Generation Process
1. **Input**: Markdown documents with technical content
2. **Audio**: Generated using Azure Cognitive Services Text-to-Speech with natural prosody
3. **Slides**: Title slide created with ImageMagick
4. **Video**: FFmpeg loops slide for audio duration with H.264 encoding
5. **Output**: Playable MP4 files (1-5MB each)

## Usage
- Watch videos for learning and reference
- Use in presentations or training materials
- Share for team knowledge distribution
- Playable on any device with MP4 support

## Notes
- Each video is self-contained with audio narration
- Static slide design ensures compatibility and quick loading
- Total video library: ~20-30 minutes of narrated content
- All proprietary terminology has been removed for compliance

## Regeneration
To regenerate videos:
```powershell
# 1. Generate audio (requires Azure TTS key)
.\Generate-Audio.ps1 -TtsKey "your-key" -TtsRegion eastus

# 2. Generate slides
.\Generate-Slides.ps1

# 3. Generate videos
.\Generate-Videos-Final.ps1
```

See `GENERATE-AUDIO-VIDEO.md` for detailed instructions.
