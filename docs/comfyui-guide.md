---
layout: default
title: ComfyUI Complete Guide
nav_order: 10
---

# ComfyUI — The Complete Dummies Guide

Everything you need to know to use ComfyUI: downloading models, uploading your own images, generating images and videos, and creating marketing clips for tool-box.ninja.

> **Installation** is handled by the NinjaMenu installer (`ninjamenu` > Llm > Ai-Tools > Comfyui). This guide assumes ComfyUI is already installed at `/opt/apps/LLM/ComfyUI`.

---

## Table of Contents

1. [Starting and Stopping ComfyUI](#starting-and-stopping-comfyui)
2. [The ComfyUI Interface](#the-comfyui-interface)
3. [Downloading Models](#downloading-models)
4. [Your First Image](#your-first-image)
5. [Uploading PNG Files (Logos, Screenshots)](#uploading-png-files-logos-screenshots)
6. [Text-to-Video (Marketing Clips)](#text-to-video-marketing-clips)
7. [Image-to-Video (Animate a Logo)](#image-to-video-animate-a-logo)
8. [Creating a 10-Second Marketing Clip for tool-box.ninja](#creating-a-10-second-marketing-clip-for-tool-boxninja)
9. [Exporting Your Final Video](#exporting-your-final-video)
10. [Troubleshooting](#troubleshooting)
11. [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)

---

## Starting and Stopping ComfyUI

### Start

```bash
cd /opt/apps/LLM/ComfyUI
source venv/bin/activate
python3 main.py
```

Then open your browser to: **http://127.0.0.1:8188**

| Startup Option | What It Does |
|----------------|-------------|
| `python3 main.py` | Default — localhost only |
| `python3 main.py --listen 0.0.0.0` | Access from other devices on your network |
| `python3 main.py --port 8189` | Use a different port |
| `python3 main.py --lowvram` | Use less memory (slower but avoids crashes) |

### Stop

Press `Ctrl+C` in the terminal, or:

```bash
lsof -ti :8188 | xargs kill
```

---

## The ComfyUI Interface

When you open `http://127.0.0.1:8188` you'll see:

- **Canvas** — The big area where you drag and connect nodes
- **Queue Prompt** button (top right) — Click to run your workflow
- **Manager** button — Install custom nodes and models (via ComfyUI-Manager)
- **Right-click** on the canvas — Opens the node menu to add new nodes

### Key Controls

| Action | How |
|--------|-----|
| Add a node | Right-click on canvas, search for the node |
| Connect nodes | Drag from an output dot to an input dot |
| Move a node | Click and drag the title bar |
| Delete a node | Select it, press `Delete` |
| Pan the canvas | Middle-click drag, or `Space` + drag |
| Zoom | Scroll wheel |
| Run the workflow | Click "Queue Prompt" or `Ctrl+Enter` |
| Load default workflow | `Ctrl+D` |

### What Are Nodes?

Every operation is a box ("node") with coloured dots on the sides:
- **Left dots** = inputs (data coming in)
- **Right dots** = outputs (data going out)
- You drag a wire from an output dot to an input dot to connect them
- Colours must match — a purple CLIP output connects to a purple CLIP input

Common nodes you'll use:

| Node | What It Does |
|------|-------------|
| **Load Checkpoint** | Loads an AI model from `models/checkpoints/` |
| **CLIP Text Encode** | Turns your text prompt into something the model understands |
| **KSampler** | The actual AI generation engine — where the magic happens |
| **VAE Decode** | Converts raw AI output into a viewable image/video |
| **Save Image** | Saves the result to `output/` |
| **Load Image** | Loads a PNG/JPG you've uploaded |
| **Empty Latent Image** | Sets the size of the image to generate |
| **Empty Latent Video** | Sets the size and frame count for video |

---

## Downloading Models

Models are the AI brains. Without them, ComfyUI can't generate anything. Here's exactly where to get them and where to put them.

### Where Models Live

All models go inside `/opt/apps/LLM/ComfyUI/models/`. Each type has its own subfolder:

```
/opt/apps/LLM/ComfyUI/models/
  checkpoints/     <-- Main generation models (big, 2-12 GB each)
  loras/           <-- Style/subject add-ons (small, 50-300 MB)
  vae/             <-- Image decoder models (~300 MB)
  controlnet/      <-- Guide generation with poses/edges (~1.5 GB)
  clip/            <-- Text understanding models (usually bundled)
  upscale_models/  <-- Make images bigger and sharper (~100 MB)
```

### Method 1: ComfyUI-Manager (Easiest — Point and Click)

1. With ComfyUI running, click the **Manager** button in the browser
2. Click **Model Manager**
3. Search for a model (e.g., "SDXL", "LTX-Video")
4. Click **Install** — it downloads to the correct folder automatically
5. Wait for the download to finish, then refresh the page

### Method 2: Download from HuggingFace (Terminal)

HuggingFace is the main model hub. Open a **new terminal tab** (keep ComfyUI running in the other one) and run these commands.

#### For Image Generation — Stable Diffusion XL (SDXL) — ~6.5 GB

The best starting model for images.

```bash
cd /opt/apps/LLM/ComfyUI/models/checkpoints

curl -L -o sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
```

You'll see a progress bar. Wait for it to finish completely (~6.5 GB).

**Verify it downloaded:**
```bash
ls -lh /opt/apps/LLM/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors
# Should show approximately 6.5G
```

#### For Video Generation — LTX-Video (Best for Mac) — ~4 GB

The lightest video model. Works on 16 GB Macs.

```bash
cd /opt/apps/LLM/ComfyUI/models/checkpoints

curl -L -o ltx-video-2b-v0.9.5.safetensors \
  "https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.5.safetensors"
```

> **Note:** Filenames may change with new releases. Check https://huggingface.co/Lightricks/LTX-Video for the latest.

#### For Video Generation — Hunyuan Video (Best Quality) — ~12 GB

Only for Macs with 24 GB+ unified memory.

```bash
cd /opt/apps/LLM/ComfyUI/models/checkpoints

curl -L -o hunyuan_video.safetensors \
  "https://huggingface.co/tencent/HunyuanVideo/resolve/main/hunyuan_video_720_cfgdistill_fp8_e4m3fn.safetensors"
```

### Model Cheat Sheet

| Model | Size | Use Case | Min RAM | Download To |
|-------|------|----------|---------|------------|
| SDXL Base 1.0 | 6.5 GB | Image generation | 8 GB | `models/checkpoints/` |
| SD 1.5 | 4 GB | Faster images, AnimateDiff | 8 GB | `models/checkpoints/` |
| LTX-Video | ~4 GB | Video generation | 16 GB | `models/checkpoints/` |
| Hunyuan Video | ~12 GB | High-quality video | 24 GB | `models/checkpoints/` |
| AnimateDiff | ~1.5 GB | Animate still images | 16 GB | `models/animatediff_models/` |
| SDXL LoRA (any) | 50-300 MB | Style/subject tweaks | 8 GB | `models/loras/` |

### How to Tell If a Model Loaded Correctly

1. In ComfyUI, add a **Load Checkpoint** node (right-click > loaders > Load Checkpoint)
2. Click the model dropdown on the node
3. Your downloaded model should appear in the list
4. If it doesn't: check the file is in the right folder, check it downloaded fully, or restart ComfyUI

---

## Your First Image

### Step 1: Load the Default Workflow

When you open ComfyUI, it loads a default workflow. If the canvas is empty, press `Ctrl+D`.

### Step 2: Select Your Model

1. Find the **Load Checkpoint** node (usually top-left)
2. Click the dropdown
3. Select your downloaded model (e.g., `sd_xl_base_1.0.safetensors`)

### Step 3: Write a Prompt

1. Find the **CLIP Text Encode (Prompt)** node connected to the "positive" input
2. Type your prompt, e.g.:
   ```
   a futuristic ninja warrior in a neon-lit cyberpunk city, cinematic lighting, detailed, 4k
   ```

### Step 4: Set the Negative Prompt

1. Find the other **CLIP Text Encode** connected to "negative"
2. Type:
   ```
   blurry, low quality, distorted, ugly, watermark
   ```

### Step 5: Generate

1. Click **Queue Prompt** (top right) or press `Ctrl+Enter`
2. Watch the progress bar on the KSampler node — it fills up as it generates
3. The image appears in the **Preview Image** or **Save Image** node

### Step 6: Find Your Image

Generated images are saved to:
```
/opt/apps/LLM/ComfyUI/output/
```

### Tips for Better Images

- **Be specific** in your prompt: "a red sports car on a mountain road at sunset" beats "a car"
- **Add quality words**: `cinematic, detailed, 4k, professional photography, sharp focus`
- **Use the negative prompt** to avoid common issues: `blurry, low quality, distorted, watermark, text`
- **Change the seed** number on the KSampler to get different results from the same prompt
- **Increase steps** (25-40) for more detail, decrease (15-20) for faster drafts

---

## Uploading PNG Files (Logos, Screenshots)

You can use your own images in ComfyUI — for logos, reference images, img2img generation, or as starting frames for video.

### Method 1: Drag and Drop (Easiest)

1. Open ComfyUI in your browser
2. Drag a PNG/JPG from Finder directly onto the canvas
3. ComfyUI creates a **Load Image** node with your file automatically

### Method 2: Load Image Node (Click to Upload)

1. Right-click the canvas
2. Search for **Load Image** and add it
3. Click **choose file to upload** on the node
4. Browse to your PNG and select it

### Method 3: Copy to the Input Folder (Bulk Upload)

Copy files into ComfyUI's input folder and they appear in the Load Image dropdown:

```bash
# Copy a single logo
cp /path/to/your/logo.png /opt/apps/LLM/ComfyUI/input/

# Copy all PNGs from a folder
cp /path/to/your/*.png /opt/apps/LLM/ComfyUI/input/
```

No restart needed — images appear in the dropdown immediately.

### Loading the tool-box.ninja Brand Assets

```bash
# Copy all brand character images
cp /Users/alistairhenderson/Development/ninja_toolbox/docs/ForTheVeoClip/*.png \
   /opt/apps/LLM/ComfyUI/input/

# Copy the main logo separately
cp /Users/alistairhenderson/Development/ninja_toolbox/docs/assets/images/toolbox_ninja_logo_fca311.png \
   /opt/apps/LLM/ComfyUI/input/
```

Available brand images:

| File | What It Is |
|------|-----------|
| `toolbox_ninja_logo_fca311.png` | Main logo (orange on dark) |
| `big_tracey_ninja_fca311.png` | Big Tracey character |
| `little_tracey_ninja_fca311.png` | Little Tracey character |
| `it_nerd_fca311.png` | IT Nerd character |
| `it_super_nerd_fca311.png` | IT Super Nerd character |

### Supported File Formats

| Format | Works? | Notes |
|--------|--------|-------|
| PNG | Yes | Best for logos (supports transparency) |
| JPG/JPEG | Yes | Best for photos |
| WebP | Yes | Smaller file size |
| BMP | Yes | Large files, avoid if possible |
| GIF | Partial | First frame only |
| SVG | No | Convert to PNG first (see below) |

### Converting SVG to PNG

```bash
# Using sips (built into macOS)
sips -s format png input.svg --out output.png

# Using ImageMagick (brew install imagemagick)
convert input.svg -resize 1024x1024 output.png
```

---

## Text-to-Video (Marketing Clips)

Generate a video clip from just a text description.

### What You Need

- A video-capable model downloaded (LTX-Video or Hunyuan Video — see [Downloading Models](#downloading-models))
- ComfyUI running

### Step-by-Step: Text-to-Video with LTX-Video

#### 1. Install the Video Nodes (First Time Only)

1. Click **Manager** in ComfyUI
2. Click **Install Custom Nodes**
3. Search for "LTX-Video" or "VHS" (Video Helper Suite)
4. Install both, then restart ComfyUI

#### 2. Build the Workflow

Right-click the canvas and add these nodes:

| Node | What It Does |
|------|-------------|
| **Load Checkpoint** | Loads the LTX-Video model |
| **CLIP Text Encode** (x2) | Positive prompt + negative prompt |
| **Empty Latent Video** | Sets video dimensions and frame count |
| **KSampler** | The AI generation engine |
| **VAE Decode** | Converts AI output to viewable frames |
| **VHS Video Combine** | Saves as MP4 (from Video Helper Suite) |

#### 3. Connect the Nodes

```
Load Checkpoint ──MODEL──> KSampler
Load Checkpoint ──CLIP───> CLIP Text Encode (positive) ──> KSampler (positive)
Load Checkpoint ──CLIP───> CLIP Text Encode (negative) ──> KSampler (negative)
Load Checkpoint ──VAE────> VAE Decode
Empty Latent Video ──────> KSampler (latent_image)
KSampler ──LATENT────────> VAE Decode
VAE Decode ──IMAGE───────> VHS Video Combine
```

#### 4. Configure Each Node

**Load Checkpoint:**
- Model: `ltx-video-2b-v0.9.5.safetensors`

**CLIP Text Encode (positive):**
```
A sleek dark terminal interface with neon green text cascading down the screen,
a ninja shuriken logo glowing in orange slowly morphs into a toolbox icon,
text reveals "tool-box.ninja", cinematic lighting, smooth camera movement, 4K
```

**CLIP Text Encode (negative):**
```
blurry, low quality, distorted, static, no motion, watermark, text artifacts
```

**Empty Latent Video:**
- Width: `768`
- Height: `512`
- Frames: `120` (5 seconds at 24fps)

**KSampler:**
- Steps: `30`
- CFG: `7.0`
- Sampler: `euler`
- Scheduler: `normal`
- Seed: any number (change it to get different results)

**VHS Video Combine:**
- frame_rate: `24`
- format: `video/h264-mp4`

#### 5. Generate

Click **Queue Prompt** and wait. Video generation is slow — expect 5-30 minutes depending on your Mac and the model.

#### 6. Find Your Video

Output saves to `/opt/apps/LLM/ComfyUI/output/`

### Understanding Frame Counts

| Duration | Frames at 24fps | Frames at 25fps |
|----------|----------------|----------------|
| 3 seconds | 72 | 75 |
| 5 seconds | 120 | 125 |
| 10 seconds | 240 | 250 |
| 15 seconds | 360 | 375 |

---

## Image-to-Video (Animate a Logo)

Turn a static image (like the tool-box.ninja logo) into a moving video.

### What You Need

- A checkpoint model (SDXL or SD 1.5)
- AnimateDiff model
- Your PNG uploaded to ComfyUI

### Download AnimateDiff (First Time Only)

```bash
mkdir -p /opt/apps/LLM/ComfyUI/models/animatediff_models

cd /opt/apps/LLM/ComfyUI/models/animatediff_models
curl -L -o mm_sd15_v3.safetensors \
  "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd15_v3.safetensors"
```

### Install AnimateDiff Nodes (First Time Only)

1. Click **Manager** > **Install Custom Nodes**
2. Search for "AnimateDiff Evolved"
3. Install and restart ComfyUI

### Workflow: Animate Your Logo

1. Add a **Load Image** node > select your logo PNG
2. Add **AnimateDiff Loader** > select the `mm_sd15_v3` motion module
3. Add a **Load Checkpoint** node > select an SD 1.5 model
4. Connect through a standard img2img pipeline:
   - Load Image output connects to a **VAE Encode** node (image-to-latent)
   - VAE Encode output goes into KSampler as `latent_image`
   - Add your CLIP Text Encode nodes for positive/negative prompts
5. Set **Empty Latent Video** frames to `120` for 5 seconds
6. Use a prompt like:
   ```
   subtle zoom in, floating particles, cinematic glow, smooth motion, orange accent lighting
   ```
7. Set KSampler **denoise** to `0.5-0.7` (lower = stays closer to your original image)
8. Queue and wait

---

## Creating a 10-Second Marketing Clip for tool-box.ninja

Here's the full recipe. The most professional approach is to generate 2-3 short clips and stitch them together.

### The Stitch Approach

#### Clip 1: Terminal Scene (3 seconds, 72 frames)

**Prompt:**
```
Dark terminal window with green monospace text rapidly typing commands,
matrix-style code rain in background, orange accent lighting,
professional dev environment, smooth animation
```

#### Clip 2: Logo Reveal (4 seconds, 96 frames)

**Method:** Image-to-video using `toolbox_ninja_logo_fca311.png`

**Prompt:**
```
Glowing orange ninja logo on dark background slowly rotating,
particles floating outward, cinematic lens flare,
premium tech brand reveal, smooth 3D motion
```

#### Clip 3: Text/Tagline Reveal (3 seconds, 72 frames)

**Prompt:**
```
Dark background, text "tool-box.ninja" appearing letter by letter in orange
neon glow, minimal clean design, premium tech aesthetic, subtle particle effects
```

#### Joining the Clips with ffmpeg

```bash
# Install ffmpeg if you don't have it
brew install ffmpeg

# 1. Create a file listing the clips (update filenames to match your output)
cat > /tmp/clips.txt << 'EOF'
file '/opt/apps/LLM/ComfyUI/output/clip1_terminal.mp4'
file '/opt/apps/LLM/ComfyUI/output/clip2_logo.mp4'
file '/opt/apps/LLM/ComfyUI/output/clip3_text.mp4'
EOF

# 2. Join them into one video
ffmpeg -f concat -safe 0 -i /tmp/clips.txt -c copy \
  /opt/apps/LLM/ComfyUI/output/toolbox_ninja_10s.mp4

# 3. (Optional) Add fade in/out
ffmpeg -f concat -safe 0 -i /tmp/clips.txt \
  -vf "fade=t=in:st=0:d=0.5,fade=t=out:st=9.5:d=0.5" \
  -c:v libx264 -preset slow -crf 18 \
  /opt/apps/LLM/ComfyUI/output/toolbox_ninja_10s_fades.mp4
```

### Brand Guidelines for the Clip

| Element | Value |
|---------|-------|
| Background colour | `#000000` (Black) or `#14213d` (Prussian Blue) |
| Accent colour | `#fca311` (Orange) — logo, highlights, text glow |
| Text colour | `#ffffff` (White) |
| Font feel | Monospace / terminal aesthetic |
| Characters | Big Tracey Ninja, Little Tracey Ninja, IT Nerd, IT Super Nerd |
| Logo file | `toolbox_ninja_logo_fca311.png` |
| Tagline | "Your Dev Toolkit" |

---

## Exporting Your Final Video

### Output Location

All generated content saves to:
```
/opt/apps/LLM/ComfyUI/output/
```

### ffmpeg Recipes

```bash
# Install ffmpeg if needed
brew install ffmpeg

# Convert to MP4 (H.264 — plays everywhere)
ffmpeg -i input.webm -c:v libx264 -preset slow -crf 18 -c:a aac output.mp4

# Resize to 1080p
ffmpeg -i input.mp4 -vf scale=1920:1080 -c:v libx264 -preset slow -crf 18 output_1080p.mp4

# Create a GIF (for social media / README)
ffmpeg -i input.mp4 -vf "fps=15,scale=480:-1" -loop 0 output.gif

# Trim to exactly 10 seconds
ffmpeg -i input.mp4 -t 10 -c copy output_10s.mp4

# Add background music
ffmpeg -i video.mp4 -i music.mp3 -c:v copy -c:a aac -shortest output_with_audio.mp4

# Extract a single frame as PNG (e.g. for thumbnail)
ffmpeg -i video.mp4 -ss 00:00:03 -frames:v 1 thumbnail.png
```

---

## Troubleshooting

### Model doesn't appear in the dropdown

1. Check the file is in the correct `models/` subfolder
2. Check the file downloaded completely (compare file size with `ls -lh`)
3. Restart ComfyUI (model list refreshes on startup)

### Port 8188 already in use

```bash
lsof -ti :8188 | xargs kill
```

### Generation is extremely slow

- macOS uses MPS (Metal) not CUDA — it's slower than NVIDIA GPUs, this is normal
- Use smaller resolution (512x512 instead of 1024x1024)
- Use fewer steps (20 instead of 30)
- Use fewer frames for video (60 instead of 120)
- Close other apps to free RAM

### MPS memory errors

- Reduce image/video resolution
- Use a smaller model
- Close other apps
- Start with `--lowvram` flag: `python3 main.py --lowvram`

### Video generation produces black frames

- Lower the CFG value (try 3-5 instead of 7)
- Use more steps (40 instead of 30)
- Try a different seed number
- Make sure you're using a video-capable model (not an image-only checkpoint)

### Uploaded image doesn't appear in the dropdown

- Check it's in `/opt/apps/LLM/ComfyUI/input/`
- Check the file format is supported (PNG, JPG, WebP — not SVG)
- Click the refresh button on the Load Image node

---

## Quick Reference Cheat Sheet

### Start / Stop

```bash
# Start
cd /opt/apps/LLM/ComfyUI && source venv/bin/activate && python3 main.py

# Stop
lsof -ti :8188 | xargs kill
```

Open: **http://127.0.0.1:8188**

### Key Folders

| Folder | What Goes Here |
|--------|---------------|
| `models/checkpoints/` | Main AI models (SDXL, LTX-Video, etc.) |
| `models/loras/` | Style/subject add-ons |
| `models/controlnet/` | Pose/edge guide models |
| `models/animatediff_models/` | AnimateDiff motion modules |
| `input/` | Your uploaded images (logos, PNGs, screenshots) |
| `output/` | Generated images and videos |
| `custom_nodes/` | Plugins and extensions |

### Generation Settings

| Setting | Image | Video (10s) |
|---------|-------|-------------|
| Width | 1024 | 768 |
| Height | 1024 | 512 |
| Steps | 20-30 | 25-30 |
| CFG | 7-8 | 5-7 |
| Frames | 1 | 240 (at 24fps) |
| Sampler | euler_ancestral | euler |

### Quick Commands

```bash
# Upload an image
cp your_image.png /opt/apps/LLM/ComfyUI/input/

# Download a model
cd /opt/apps/LLM/ComfyUI/models/checkpoints
curl -L -o model.safetensors "https://huggingface.co/org/model/resolve/main/file.safetensors"

# Upload all brand assets
cp ~/Development/ninja_toolbox/docs/ForTheVeoClip/*.png /opt/apps/LLM/ComfyUI/input/
```
