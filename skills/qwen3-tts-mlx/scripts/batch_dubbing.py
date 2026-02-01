#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Qwen3-TTS MLX batch dubbing script
Optimized for Apple Silicon (M1/M2/M3/M4)

Dependencies:
    pip install mlx-audio soundfile numpy

Example:
    python batch_dubbing.py --input dubbing.json --out-dir outputs
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path


DEFAULT_MODEL = "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit"


def load_dubbing_script(input_path: str) -> list:
    """Load dubbing JSON."""
    with open(input_path, "r", encoding="utf-8") as f:
        return json.load(f)


def generate_segment(
    text: str,
    voice: str,
    lang_code: str,
    instruct: str,
    output_path: str,
    model: str,
) -> bool:
    """Generate a single segment."""
    cmd = [
        sys.executable,
        "-m",
        "mlx_audio.tts.generate",
        "--model",
        model,
        "--text",
        text,
        "--voice",
        voice,
        "--lang_code",
        lang_code,
        "--output_path",
        output_path,
    ]

    if instruct:
        cmd.extend(["--instruct", instruct])

    result = subprocess.run(cmd, capture_output=True)
    return result.returncode == 0


def merge_audio_files(
    segment_files: list,
    output_path: str,
    silence_gap: float,
    character_switch_gap: float,
    speakers: list,
) -> bool:
    """Merge audio files with optional gaps."""
    import tempfile

    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
        prev_speaker = None
        for i, (seg_file, speaker) in enumerate(zip(segment_files, speakers)):
            f.write(f"file '{seg_file}'\n")

            if i < len(segment_files) - 1:
                gap = (
                    character_switch_gap
                    if prev_speaker and prev_speaker != speaker
                    else silence_gap
                )
                f.write(f"file 'anullsrc=r=24000:cl=mono:d={gap}'\n")

            prev_speaker = speaker

        list_file = f.name

    cmd = [
        "ffmpeg",
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        list_file,
        "-c",
        "copy",
        output_path,
    ]

    try:
        import numpy as np
        import soundfile as sf

        all_audio = []
        sample_rate = 24000

        for i, (seg_file, speaker) in enumerate(zip(segment_files, speakers)):
            audio, sr = sf.read(seg_file)
            all_audio.append(audio)

            if i < len(segment_files) - 1:
                gap = (
                    character_switch_gap
                    if prev_speaker and prev_speaker != speaker
                    else silence_gap
                )
                silence = np.zeros(int(sample_rate * gap), dtype=np.float32)
                all_audio.append(silence)

            prev_speaker = speaker

        final_audio = np.concatenate(all_audio)
        sf.write(output_path, final_audio, sample_rate)
        return True
    except Exception as e:
        print(f"Merge failed: {e}")
        return False


def run_batch_dubbing(args):
    """Run batch dubbing from a JSON script."""
    print(f"Loading script: {args.input}")
    segments = load_dubbing_script(args.input)
    print(f"Segments: {len(segments)}")

    out_dir = Path(args.out_dir).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    segments_dir = out_dir / "segments"
    segments_dir.mkdir(exist_ok=True)

    model = args.model or DEFAULT_MODEL
    print(f"Model: {model}")

    segment_files = []
    speakers = []

    for i, seg in enumerate(segments):
        text = seg.get("text", "")
        voice = seg.get("voice", seg.get("speaker", "Vivian"))
        lang_code = seg.get("lang_code", seg.get("lang", "Chinese"))
        instruct = seg.get("instruct", "")

        print(f"\n[{i+1}/{len(segments)}] Generating: {text[:30]}...")
        print(f"  Voice: {voice}, Style: {instruct or 'default'}")

        segment_path = segments_dir / f"seg_{i+1:03d}_{voice}.wav"
        success = generate_segment(
            text=text,
            voice=voice,
            lang_code=lang_code,
            instruct=instruct,
            output_path=str(segment_path),
            model=model,
        )

        if success:
            segment_files.append(str(segment_path))
            speakers.append(voice)
            print(f"  Saved: {segment_path.name}")
        else:
            print("  Generation failed")

    if not segment_files:
        print("\nNo segments generated")
        return

    print(f"\nMerging {len(segment_files)} segments...")
    input_stem = Path(args.input).stem.replace(".dubbing", "")
    final_path = out_dir / f"{input_stem}_final.wav"

    success = merge_audio_files(
        segment_files=segment_files,
        output_path=str(final_path),
        silence_gap=args.silence_gap,
        character_switch_gap=args.character_switch_gap,
        speakers=speakers,
    )

    if success:
        print("\nDone")
        print(f"  Segments dir: {segments_dir}")
        print(f"  Final file: {final_path}")
    else:
        print(f"\nMerge failed, segments kept in: {segments_dir}")

    import shutil

    shutil.copy(args.input, out_dir / Path(args.input).name)

    if args.clean_segments and success:
        print("Cleaning segments...")
        shutil.rmtree(segments_dir)


def main():
    parser = argparse.ArgumentParser(
        description="Qwen3-TTS MLX batch dubbing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Dubbing JSON format:
  [
    {"text": "First segment", "voice": "Vivian", "lang_code": "Chinese", "instruct": "narration"},
    {"text": "Second segment", "voice": "Ryan", "lang_code": "English", "instruct": "excited"}
  ]

Example:
  python batch_dubbing.py --input article.dubbing.json --out-dir outputs
        """,
    )

    parser.add_argument("--input", required=True, help="Dubbing JSON file path")
    parser.add_argument("--out-dir", default="./outputs", help="Output directory (default: ./outputs)")
    parser.add_argument("--model", help=f"Model name (default: {DEFAULT_MODEL})")
    parser.add_argument(
        "--silence-gap",
        type=float,
        default=0.3,
        help="Silence between segments in seconds (default: 0.3)",
    )
    parser.add_argument(
        "--character-switch-gap",
        type=float,
        default=0.5,
        help="Silence when switching speakers in seconds (default: 0.5)",
    )
    parser.add_argument(
        "--clean-segments",
        action="store_true",
        help="Delete intermediate segments after merge",
    )

    args = parser.parse_args()

    print("=" * 50)
    print("Qwen3-TTS MLX Batch Dubbing")
    print("=" * 50)

    run_batch_dubbing(args)


if __name__ == "__main__":
    main()
