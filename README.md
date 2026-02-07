# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions and scripts that extend agent capabilities.

Skills follow the Agent Skills format.

Chinese version: [README.zh-CN.md](README.zh-CN.md)

## Available Skills

### gemini-watermark

Remove visible Gemini AI watermarks from images via reverse alpha blending. Fast, offline, single binary with zero runtime dependencies.

**Use when:**
- Removing the Gemini star/sparkle logo watermark from AI-generated images
- Batch processing a directory of Gemini-generated images
- Cleaning images before publishing or sharing

**Features:**
- Mathematically accurate reverse alpha blending
- Three-stage watermark detection (skip non-watermarked images)
- Pre-built binaries for macOS, Linux, Windows
- One-click installer (no Rust required)
- Supports JPEG, PNG, WebP, BMP formats

### libvips-image

High-performance image processing with libvips. Fast, memory-efficient operations for resize, convert, watermark, and batch processing.

**Use when:**
- Resizing, cropping, or creating thumbnails
- Converting between formats (JPEG, PNG, WebP, AVIF, HEIC)
- Adding watermarks or text overlays
- Batch processing large numbers of images
- Working with large images that need low memory usage

**Features:**
- 13 image operations (resize, thumbnail, convert, crop, rotate, watermark, composite, adjust, sharpen, blur, flip, grayscale, info)
- Batch processing with parallel workers
- Cross-platform: macOS, Linux, Windows
- One-click installers with uv support
- 10-100x less memory than ImageMagick/PIL

### qwen3-tts-mlx

Local Qwen3-TTS speech synthesis on Apple Silicon via MLX. Supports CustomVoice, VoiceDesign, and VoiceClone for offline narration and multilingual TTS.

**Use when:**
- Generating speech locally on a Mac
- Creating narration, audiobooks, or video voiceovers
- Need controllable style or custom voice design

**Features:**
- Built-in voices (CustomVoice)
- Voice design via natural language prompts
- Voice cloning from reference audio
- Batch dubbing scripts

## Installation

```bash
npx skills add AGISeek/agent-skills
```

## Usage

Skills are automatically available once installed. The agent will use them when relevant tasks are detected.

**Examples:**
```
Generate a news-style Chinese male narration locally
```
```
Create a custom voice using VoiceDesign
```

## Skill Structure

Each skill contains:
- `SKILL.md` - Instructions for the agent
- `scripts/` - Helper scripts (optional)
- `references/` - Supporting documentation (optional)

## License

MIT
