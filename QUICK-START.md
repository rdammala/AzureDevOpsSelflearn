# 🚀 Quick Start: Generate Audio & Video Training (5 Minutes)

## Step 1: Get Your Free Azure TTS Key (2 minutes)

### A. Create Free Azure Account
```
1. Go to: https://azure.microsoft.com/free/
2. Click "Start free"
3. Sign in or create account
4. Verify with credit card (no charges for free tier!)
```

### B. Create Cognitive Services Resource
```
1. Go to: https://portal.azure.com
2. Click "+ Create a resource"
3. Search for: "Speech"
4. Click "Speech services"
5. Fill in:
   - Name: "AzureDevOpsAudio"
   - Region: "East US"
   - Pricing tier: "Free F0" (FREE!)
   - Create
6. Wait for deployment (30 seconds)
7. Go to resource
8. Click "Keys and Endpoint" (left menu)
9. Copy Key 1 → save it
```

✅ **Done! You have your free API key**

---

## Step 2: Install Prerequisites (1 minute)

### A. Install FFmpeg (for video creation)

**On Windows with Chocolatey:**
```powershell
choco install ffmpeg -y
```

**Without Chocolatey:**
- Download: https://ffmpeg.org/download.html
- Extract to: `C:\Program Files\ffmpeg`
- Add to PATH (Google "add to PATH Windows")

### B. Install ImageMagick (for slides) - OPTIONAL

```powershell
choco install imagemagick -y
```

✅ **Done! Prerequisites installed**

---

## Step 3: Run the Generation Script (2 minutes)

### A. Open PowerShell

```powershell
# Navigate to the learning library folder
cd "c:\SupportServices\AzureDevOpsSelflearn"

# Allow script execution (one-time)
Set-ExecutionPolicy -ExecutionScope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### B. Run the Master Script

```powershell
# Set your Azure key
$key = "YOUR_KEY_HERE"  # Replace with key from Step 1

# Run the complete generation
./Run-AudioVideo-Generation.ps1 -TtsKey $key
```

### C. Watch the Magic Happen ✨

```
🎙️  Generating audio files...
    ✅ 01-Git-Workflow-Branching.mp3
    ✅ 02-CI-CD-Pipelines.mp3
    ... (11 total)

🎬 Creating videos...
    ✅ 01-Git-Workflow-Branching.mp4
    ... (more videos)

✅ Generation complete!
```

---

## What You Get

### Audio Files (in `audio/` folder)
```
📁 audio/
├─ 01-Git-Workflow-Branching.mp3 (8.2MB)
├─ 02-CI-CD-Pipelines.mp3 (6.5MB)
├─ 03-Infrastructure-as-Code-Bicep.mp3 (6.1MB)
├─ 04-Testing-Strategy.mp3 (5.8MB)
├─ 05-Blue-Green-Deployment.mp3 (5.4MB)
├─ 06-Troubleshooting-Recovery.mp3 (6.2MB)
├─ 07-DevOps-Concepts.mp3 (6.8MB)
├─ 08-Cost-Optimization.mp3 (5.9MB)
├─ 09-YAML-Configuration.mp3 (6.1MB)
├─ 10-OneBranch-vs-Other-Tools.mp3 (6.4MB)
└─ 11-Containers-Orchestration.mp3 (6.2MB)

Total: ~130 minutes of audio content (~65MB)
✅ Podcast-ready format
✅ Multiple voices (alternating for variety)
```

### Video Files (in `videos/` folder)
```
📁 videos/
├─ 01-Git-Workflow-Branching.mp4 (450MB)
├─ 02-CI-CD-Pipelines.mp4 (380MB)
├─ ... more videos
└─ 11-Containers-Orchestration.mp4 (420MB)

Total: ~4-5GB of training videos
✅ 1080p quality
✅ Synced audio + slides
✅ Ready to upload to YouTube or LMS
```

---

## 💰 Cost Breakdown (You Pay ZERO!)

| Service | Limit | Used | Cost |
|---------|-------|------|------|
| **Azure Text-to-Speech** | 500,000 chars/month | ~70,000 | **FREE** ✅ |
| **FFmpeg** | Unlimited | Open source | **FREE** ✅ |
| **ImageMagick** | Unlimited | Open source | **FREE** ✅ |
| **Azure Blob Storage** | 5GB first year | ~5GB | **FREE** ✅ |
| **Total Cost** | | | **$0** ✅ |

---

## 🎯 What To Do Next

### Option 1: Share as Podcast
```
1. Upload audio files to podcast hosting:
   - Anchor (Spotify owned, free)
   - Buzzsprout (free tier)
   - Podbean (free tier)

2. Share podcast URL:
   - Spotify
   - Apple Podcasts
   - Google Podcasts

3. Team can listen on the go!
```

### Option 2: Host on YouTube
```
1. Create YouTube channel (free)
2. Upload video files
3. Set visibility to "Public" or "Unlisted"
4. Share link with team

🎬 30-minute videos perfect for training!
```

### Option 3: Upload to Azure Storage
```
1. Create free Azure Storage account
   - https://portal.azure.com
   - Create storage account (free tier)
   - Create "audio" and "videos" containers

2. Upload files:
   powershell
   # Upload audio
   Get-ChildItem "./audio" | ForEach-Object {
       Set-AzStorageBlobContent -File $_.FullName `
           -Container "audio" -Context $storageContext
   }

3. Get public URLs:
   https://mystg.blob.core.windows.net/audio/file.mp3
   https://mystg.blob.core.windows.net/videos/file.mp4

4. Share with team!
```

### Option 4: Host on Internal LMS
```
1. Upload to your company LMS (Moodle, Canvas, etc.)
2. Organize as training course
3. Track completion
4. Quiz learners on content
```

---

## ✅ Troubleshooting

### Problem: "Azure TTS Key Error"
```
Solution:
1. Check key is correct (no extra spaces)
2. Check region matches your resource region
3. Check key is "Free F0" tier (not Paid)
4. Generate new key if needed
```

### Problem: "FFmpeg not found"
```
Solution:
1. Install: choco install ffmpeg -y
2. Close and reopen PowerShell
3. Verify: ffmpeg -version
```

### Problem: "Script execution blocked"
```
Solution:
Set-ExecutionPolicy -ExecutionScope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### Problem: "Slow audio generation"
```
Note: This is normal!
- Azure TTS adds delays to avoid rate limiting
- 11 documents ≈ 3-5 minutes total
- You can see progress in the output

Solution: Let it finish! (Safe to walk away)
```

### Problem: "Video generation slow"
```
Note: FFmpeg encoding takes time
- ~30-60 seconds per video
- 11 videos ≈ 5-10 minutes
- Use task monitor to see ffmpeg.exe using CPU

Solution: Patient required! (Safe to walk away)
```

---

## 📱 Quick Commands Reference

```powershell
# List all audio files
Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\audio" -Filter "*.mp3"

# List all video files
Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\videos" -Filter "*.mp4"

# Calculate total audio size
(Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\audio" -Filter "*.mp3" | 
    Measure-Object -Property Length -Sum).Sum / 1MB

# Calculate total video size
(Get-ChildItem "c:\SupportServices\AzureDevOpsSelflearn\videos" -Filter "*.mp4" | 
    Measure-Object -Property Length -Sum).Sum / 1GB

# Play audio file
& "c:\SupportServices\AzureDevOpsSelflearn\audio\01-Git-Workflow-Branching.mp3"
```

---

## 🎯 Expected Timeline

| Step | Time | What Happens |
|------|------|--------------|
| Azure Setup | 2 min | Create account, get API key |
| Install FFmpeg | 1 min | Download/install tool |
| Run Script | 3-5 min | Generate audio files |
| Video Gen | 5-10 min | Create video files |
| **Total** | **~20 min** | Training content ready! |

---

## ✨ Result

### You Now Have:
✅ **11 podcast-quality MP3 files** (~130 minutes)
✅ **11 video files** (1080p, synced with audio)
✅ **Zero cost** (all free tier)
✅ **Professional quality** (Azure neural voices)
✅ **Ready to share** with your team

### You Can:
🎧 Listen on Spotify/Apple Podcasts
📺 Upload to YouTube
🎓 Load into LMS for training
📤 Share on Slack/Teams
🌐 Host on company intranet

---

## 🆘 Need Help?

If you encounter issues:

1. **Check prerequisites:**
   ```powershell
   ffmpeg -version
   magick -version
   ```

2. **Test Azure connection:**
   - Try key in another tool (e.g., Azure Speech Studio)
   - Ensure region matches (East US for free tier)

3. **Check logs:**
   - PowerShell shows detailed progress
   - Look for error messages
   - Search error message online

4. **Try manual approach:**
   - Run `Generate-Audio.ps1` alone
   - Run `Generate-Videos.ps1` alone
   - Combine results manually

---

## 🎉 Congratulations!

You now have professional training content generated entirely with **free Azure tools**!

**Share the knowledge!** 🚀

