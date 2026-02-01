#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Qwen3-TTS MLX CLI runner
Optimized for Apple Silicon (M1/M2/M3/M4)

Dependencies:
    pip install mlx-audio soundfile

Examples:
    # CustomVoice
    python run_tts.py custom-voice --text "Hello" --voice Vivian --lang_code Chinese

    # VoiceDesign
    python run_tts.py voice-design --text "Hello" --instruct "warm, youthful female voice"

    # VoiceClone
    python run_tts.py voice-clone --text "Hello" --ref_audio ref.wav --ref_text "Reference transcript"
"""

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

# Suppress noisy warnings before importing mlx_audio
os.environ.setdefault("TRANSFORMERS_VERBOSITY", "error")

from mlx_audio.tts.generate import generate_audio


DEFAULT_MODELS = {
    "custom-voice": "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit",
    "voice-design": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-5bit",
    "voice-clone": "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-4bit",
}


def get_output_components(output: str | None, out_dir: str, prefix: str):
    """Resolve output directory, prefix, and format.

    If output is specified:
      - Absolute path: use its directory
      - Relative path with directory: use that directory
      - Filename only: use out_dir
    """
    if output:
        output_path = Path(output).expanduser()
        if output_path.is_absolute():
            out_dir_path = output_path.parent
            out_dir_path.mkdir(parents=True, exist_ok=True)
        elif output_path.parent != Path("."):
            # Has directory component like "foo/bar.wav"
            out_dir_path = output_path.parent
            out_dir_path.mkdir(parents=True, exist_ok=True)
        else:
            # Just filename like "output.wav" - use current directory
            out_dir_path = Path(".")

        stem = output_path.stem
        ext = output_path.suffix.lstrip(".") or "wav"
        return str(out_dir_path), stem, ext, True

    # No output specified, use out_dir with timestamp
    out_dir_path = Path(out_dir).expanduser()
    out_dir_path.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return str(out_dir_path), f"{prefix}_{timestamp}", "wav", False


def run_custom_voice(args):
    """CustomVoice: built-in voices."""
    model = args.model or DEFAULT_MODELS["custom-voice"]
    out_dir, prefix, audio_format, join_audio = get_output_components(
        args.output, args.out_dir, "custom_voice"
    )

    generate_audio(
        text=args.text,
        model=model,
        voice=args.voice,
        instruct=args.instruct,
        speed=args.speed or 1.0,
        lang_code=args.lang_code,
        output_path=out_dir,
        file_prefix=prefix,
        audio_format=audio_format,
        join_audio=join_audio,
        play=False,
        verbose=True,
    )


def run_voice_design(args):
    """VoiceDesign: describe a new voice."""
    model = args.model or DEFAULT_MODELS["voice-design"]
    out_dir, prefix, audio_format, join_audio = get_output_components(
        args.output, args.out_dir, "voice_design"
    )

    generate_audio(
        text=args.text,
        model=model,
        voice=None,
        instruct=args.instruct,
        speed=args.speed or 1.0,
        lang_code=args.lang_code,
        output_path=out_dir,
        file_prefix=prefix,
        audio_format=audio_format,
        join_audio=join_audio,
        play=False,
        verbose=True,
    )


def run_voice_clone(args):
    """VoiceClone: clone from reference audio."""
    model = args.model or DEFAULT_MODELS["voice-clone"]
    out_dir, prefix, audio_format, join_audio = get_output_components(
        args.output, args.out_dir, "voice_clone"
    )

    generate_audio(
        text=args.text,
        model=model,
        voice=None,
        ref_audio=args.ref_audio,
        ref_text=args.ref_text,
        speed=args.speed or 1.0,
        output_path=out_dir,
        file_prefix=prefix,
        audio_format=audio_format,
        join_audio=join_audio,
        play=False,
        verbose=True,
    )


def main():
    parser = argparse.ArgumentParser(
        description="Qwen3-TTS MLX speech synthesis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # CustomVoice
  python run_tts.py custom-voice --text "Hello" --voice Vivian --lang_code Chinese

  # VoiceDesign
  python run_tts.py voice-design --text "Hello" --instruct "mature male announcer" --lang_code English

  # VoiceClone
  python run_tts.py voice-clone --text "Hello" --ref_audio ref.wav --ref_text "Reference transcript"
        """,
    )

    subparsers = parser.add_subparsers(dest="mode", help="TTS mode")

    cv_parser = subparsers.add_parser("custom-voice", help="Generate with built-in voices")
    cv_parser.add_argument("--text", required=True, help="Text to synthesize")
    cv_parser.add_argument(
        "--voice",
        default="Vivian",
        choices=[
            "Vivian",
            "Serena",
            "Uncle_Fu",
            "Dylan",
            "Eric",
            "Ryan",
            "Aiden",
            "Ono_Anna",
            "Sohee",
        ],
        help="Voice name (default: Vivian)",
    )
    cv_parser.add_argument(
        "--lang_code",
        default="Chinese",
        choices=["Chinese", "English", "Japanese", "Korean"],
        help="Language (default: Chinese)",
    )
    cv_parser.add_argument("--instruct", help="Style instruction (e.g., calm, warm)")
    cv_parser.add_argument("--model", help="Model name (default: 0.6B-CustomVoice-4bit)")
    cv_parser.add_argument("--speed", type=float, help="Speech speed")
    cv_parser.add_argument("--output", help="Output file name (e.g., output.wav)")
    cv_parser.add_argument("--out-dir", default="./outputs", help="Output directory when --output not specified")

    vd_parser = subparsers.add_parser("voice-design", help="Design a new voice")
    vd_parser.add_argument("--text", required=True, help="Text to synthesize")
    vd_parser.add_argument("--instruct", required=True, help="Voice description")
    vd_parser.add_argument(
        "--lang_code",
        default="Chinese",
        choices=["Chinese", "English", "Japanese", "Korean"],
        help="Language (default: Chinese)",
    )
    vd_parser.add_argument("--model", help="Model name (default: 1.7B-VoiceDesign-5bit)")
    vd_parser.add_argument("--speed", type=float, help="Speech speed")
    vd_parser.add_argument("--output", help="Output file name")
    vd_parser.add_argument("--out-dir", default="./outputs", help="Output directory when --output not specified")

    vc_parser = subparsers.add_parser("voice-clone", help="Clone from reference audio")
    vc_parser.add_argument("--text", required=True, help="Text to synthesize")
    vc_parser.add_argument("--ref_audio", required=True, help="Reference audio path")
    vc_parser.add_argument("--ref_text", required=True, help="Reference transcript")
    vc_parser.add_argument("--model", help="Model name (default: 0.6B-Base-4bit)")
    vc_parser.add_argument("--speed", type=float, help="Speech speed")
    vc_parser.add_argument("--output", help="Output file name")
    vc_parser.add_argument("--out-dir", default="./outputs", help="Output directory when --output not specified")

    args = parser.parse_args()

    if not args.mode:
        parser.print_help()
        sys.exit(1)

    if args.mode == "custom-voice":
        run_custom_voice(args)
    elif args.mode == "voice-design":
        run_voice_design(args)
    elif args.mode == "voice-clone":
        run_voice_clone(args)


if __name__ == "__main__":
    main()
