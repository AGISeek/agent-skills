# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions and scripts that extend agent capabilities.

Skills follow the Agent Skills format.

Chinese version: [README.zh-CN.md](README.zh-CN.md)

## Available Skills

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
