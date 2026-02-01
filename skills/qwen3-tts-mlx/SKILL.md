---
name: qwen3-tts-mlx
description: Local Qwen3-TTS speech synthesis on Apple Silicon via MLX. Use for offline narration, audiobooks, video voiceovers, and multilingual TTS.
metadata:
  author: agiseek
  version: "1.0.1"
---

# Qwen3-TTS MLX

Run Qwen3-TTS locally on Apple Silicon (M1/M2/M3/M4) using MLX.

## When to Use

- Generate speech fully offline on a Mac
- Produce narration, audiobooks, podcasts, or video voiceovers
- Create multilingual TTS with controllable style
- Prototype with built-in voices or design a new voice

## Quick Start

### Install

```bash
pip install mlx-audio
brew install ffmpeg
```

### Single Sentence

```bash
python -m mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit \
  --text "Hello, welcome to local text to speech." \
  --voice Ryan \
  --lang_code English \
  --output_path output.wav
```

### With Style Control

```bash
python -m mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit \
  --text "Today we break down a long interview." \
  --voice Uncle_Fu \
  --lang_code Chinese \
  --instruct "news anchor tone, calm and clear" \
  --output_path output.wav
```

## Model Guide

### CustomVoice (built-in voices + style control)

| Model | Size | Memory | Use Case |
|------|------|--------|----------|
| `mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit` | ~1GB | ~3GB | Fast local TTS (recommended) |

### VoiceDesign (describe a new voice)

| Model | Size | Memory | Use Case |
|------|------|--------|----------|
| `mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-5bit` | ~2GB | ~5GB | Custom voice design |
| `mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-6bit` | ~2.5GB | ~6GB | Higher quality voice design |

### Base (voice cloning)

| Model | Size | Memory | Use Case |
|------|------|--------|----------|
| `mlx-community/Qwen3-TTS-12Hz-0.6B-Base-4bit` | ~1GB | ~3GB | Fast voice clone |
| `mlx-community/Qwen3-TTS-12Hz-0.6B-Base-6bit` | ~1.5GB | ~4GB | Higher quality clone |

## Modes

### 1) CustomVoice

Use built-in voices with optional style control.

```bash
python -m mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit \
  --text "This is a test sentence." \
  --voice Vivian \
  --lang_code Chinese \
  --instruct "soft, slow delivery" \
  --output_path output.wav
```

**Built-in Voices (CustomVoice)**

| Voice | Language | Notes |
|------|----------|-------|
| Vivian | Chinese | Female |
| Serena | Chinese | Female |
| Uncle_Fu | Chinese | Male |
| Dylan | Chinese | Male |
| Eric | Chinese | Male |
| Ryan | English | Male |
| Aiden | English | Male |
| Ono_Anna | Japanese | Female |
| Sohee | Korean | Female |

**Voice Selection Rules (agent guidance)**

1) If the user specifies a voice name, pass it verbatim in `--voice`.
2) If the user only specifies language/accent, choose a voice for that language.
3) If the user specifies a style (e.g., news, calm, energetic), map to the closest default below.
4) If the request needs a voice not in the list, switch to VoiceDesign or VoiceClone.

**Scenario/Keywords -> Voice**

| Scenario | Voice |
|----------|-------|
| Chinese male, news or narration | Uncle_Fu |
| Chinese male, casual or lively | Eric |
| Chinese male, neutral | Dylan |
| Chinese female, bright/young | Vivian |
| Chinese female, gentle/soft | Serena |
| English male, energetic | Ryan |
| English male, clear/neutral | Aiden |
| Japanese female | Ono_Anna |
| Korean female | Sohee |

### 2) VoiceDesign

Describe the voice in natural language using `--instruct`.

```bash
python -m mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-5bit \
  --text "Welcome back." \
  --lang_code English \
  --instruct "warm, mature male narrator with low pitch"
```

Note: In VoiceDesign, `--instruct` describes timbre and identity, not emotion.

### 3) VoiceClone

Clone a voice from a short reference audio clip.

```bash
python -m mlx_audio.tts.generate \
  --model mlx-community/Qwen3-TTS-12Hz-0.6B-Base-4bit \
  --text "Your new line goes here." \
  --ref_audio reference.wav \
  --ref_text "Transcript of the reference audio"
```

Tip: Use 5-10 seconds of clean audio for best results.

## CLI Parameters

| Parameter | Required | Description |
|----------|----------|-------------|
| `--model` | Yes | Model name (see tables above) |
| `--text` | Yes | Text to synthesize |
| `--voice` | No | Built-in voice name (CustomVoice only) |
| `--lang_code` | No | Language: Chinese/English/Japanese/Korean |
| `--instruct` | No | Style control (CustomVoice) or voice design (VoiceDesign) |
| `--output_path` | No | Output file path |
| `--ref_audio` | No | Reference audio (VoiceClone) |
| `--ref_text` | No | Transcript for reference audio |
| `--speed` | No | Speech speed |
| `--play` | No | Play after generation |

## Python API

```python
from mlx_audio.tts import Qwen3TTS
import soundfile as sf

# CustomVoice
model = Qwen3TTS("mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit")
audio = model.generate_custom_voice(
    text="Hello from Qwen3-TTS.",
    speaker="Ryan",
    lang="English",
    instruct="clear, steady delivery"
)
sf.write("output.wav", audio, 24000)
```

### VoiceDesign

```python
model = Qwen3TTS("mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-5bit")
audio = model.generate_voice_design(
    text="Test line.",
    voice_design="warm, friendly female narrator"
)
sf.write("output.wav", audio, 24000)
```

### VoiceClone

```python
model = Qwen3TTS("mlx-community/Qwen3-TTS-12Hz-0.6B-Base-4bit")
audio = model.generate(
    text="New content.",
    ref_audio="reference.wav",
    ref_text="Reference transcript"
)
sf.write("output.wav", audio, 24000)
```

## Batch Dubbing

Use `scripts/batch_dubbing.py` for long scripts:

```bash
python scripts/batch_dubbing.py \
  --input dubbing.json \
  --out-dir outputs
```

See `references/dubbing_format.md` for the JSON format.

## Troubleshooting

- If generation is slow, use the 4-bit CustomVoice model.
- If voices sound off, keep sentences shorter and add punctuation.
- If you need a different identity, switch to VoiceDesign or VoiceClone.
