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
import subprocess
import sys
from pathlib import Path
from datetime import datetime


DEFAULT_MODELS = {
    "custom-voice": "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit",
    "voice-design": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-5bit",
    "voice-clone": "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-4bit",
}


def get_output_path(output: str, out_dir: str, prefix: str = "tts") -> str:
    """Build the output file path."""
    out_dir_path = Path(out_dir).expanduser()
    out_dir_path.mkdir(parents=True, exist_ok=True)

    if output:
        if Path(output).is_absolute():
            return output
        return str(out_dir_path / output)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return str(out_dir_path / f"{prefix}_{timestamp}.wav")


def run_custom_voice(args):
    """CustomVoice: built-in voices."""
    model = args.model or DEFAULT_MODELS["custom-voice"]
    output_path = get_output_path(args.output, args.out_dir, "custom_voice")

    cmd = [
        sys.executable, "-m", "mlx_audio.tts.generate",
        "--model", model,
        "--text", args.text,
        "--voice", args.voice,
        "--lang_code", args.lang_code,
        "--output_path", output_path,
    ]

    if args.instruct:
        cmd.extend(["--instruct", args.instruct])

    if args.speed:
        cmd.extend(["--speed", str(args.speed)])

    print("=" * 50)
    print("Qwen3-TTS MLX - CustomVoice")
    print("=" * 50)
    print(f"Model: {model}")
    print(f"Text: {args.text[:50]}{'...' if len(args.text) > 50 else ''}")
    print(f"Voice: {args.voice}")
    print(f"Language: {args.lang_code}")
    if args.instruct:
        print(f"Style: {args.instruct}")
    print(f"Output: {output_path}")
    print("-" * 50)

    result = subprocess.run(cmd)

    if result.returncode == 0:
        print(f"\nSaved: {output_path}")
    else:
        print("\nGeneration failed")
        sys.exit(1)


def run_voice_design(args):
    """VoiceDesign: describe a new voice."""
    model = args.model or DEFAULT_MODELS["voice-design"]
    output_path = get_output_path(args.output, args.out_dir, "voice_design")

    cmd = [
        sys.executable, "-m", "mlx_audio.tts.generate",
        "--model", model,
        "--text", args.text,
        "--lang_code", args.lang_code,
        "--instruct", args.instruct,
        "--output_path", output_path,
    ]

    if args.speed:
        cmd.extend(["--speed", str(args.speed)])

    print("=" * 50)
    print("Qwen3-TTS MLX - VoiceDesign")
    print("=" * 50)
    print(f"Model: {model}")
    print(f"Text: {args.text[:50]}{'...' if len(args.text) > 50 else ''}")
    print(f"Voice design: {args.instruct}")
    print(f"Output: {output_path}")
    print("-" * 50)

    result = subprocess.run(cmd)

    if result.returncode == 0:
        print(f"\nSaved: {output_path}")
    else:
        print("\nGeneration failed")
        sys.exit(1)


def run_voice_clone(args):
    """VoiceClone: clone from reference audio."""
    model = args.model or DEFAULT_MODELS["voice-clone"]
    output_path = get_output_path(args.output, args.out_dir, "voice_clone")

    cmd = [
        sys.executable, "-m", "mlx_audio.tts.generate",
        "--model", model,
        "--text", args.text,
        "--ref_audio", args.ref_audio,
        "--ref_text", args.ref_text,
        "--output_path", output_path,
    ]

    if args.speed:
        cmd.extend(["--speed", str(args.speed)])

    print("=" * 50)
    print("Qwen3-TTS MLX - VoiceClone")
    print("=" * 50)
    print(f"Model: {model}")
    print(f"Text: {args.text[:50]}{'...' if len(args.text) > 50 else ''}")
    print(f"Reference audio: {args.ref_audio}")
    print(f"Output: {output_path}")
    print("-" * 50)

    result = subprocess.run(cmd)

    if result.returncode == 0:
        print(f"\nSaved: {output_path}")
    else:
        print("\nGeneration failed")
        sys.exit(1)


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
        """
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
    cv_parser.add_argument("--output", help="Output file name")
    cv_parser.add_argument("--out-dir", default="./outputs", help="Output directory (default: ./outputs)")

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
    vd_parser.add_argument("--out-dir", default="./outputs", help="Output directory (default: ./outputs)")

    vc_parser = subparsers.add_parser("voice-clone", help="Clone from reference audio")
    vc_parser.add_argument("--text", required=True, help="Text to synthesize")
    vc_parser.add_argument("--ref_audio", required=True, help="Reference audio path")
    vc_parser.add_argument("--ref_text", required=True, help="Reference transcript")
    vc_parser.add_argument("--model", help="Model name (default: 0.6B-Base-4bit)")
    vc_parser.add_argument("--speed", type=float, help="Speech speed")
    vc_parser.add_argument("--output", help="Output file name")
    vc_parser.add_argument("--out-dir", default="./outputs", help="Output directory (default: ./outputs)")

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
