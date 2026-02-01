#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Qwen3-TTS MLX 语音合成脚本
专为 Apple Silicon (M1/M2/M3/M4) 优化

依赖安装：
    pip install mlx-audio soundfile

使用示例：
    # CustomVoice 模式
    python run_tts.py custom-voice --text "你好" --voice Vivian --lang_code Chinese

    # VoiceDesign 模式
    python run_tts.py voice-design --text "你好" --instruct "可爱的女声"

    # VoiceClone 模式
    python run_tts.py voice-clone --text "你好" --ref_audio ref.wav --ref_text "参考文本"
"""

import argparse
import subprocess
import sys
from pathlib import Path
from datetime import datetime


# 默认模型
DEFAULT_MODELS = {
    "custom-voice": "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit",
    "voice-design": "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-5bit",
    "voice-clone": "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-4bit",
}


def get_output_path(output: str, out_dir: str, prefix: str = "tts") -> str:
    """生成输出文件路径"""
    out_dir_path = Path(out_dir).expanduser()
    out_dir_path.mkdir(parents=True, exist_ok=True)

    if output:
        if Path(output).is_absolute():
            return output
        return str(out_dir_path / output)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return str(out_dir_path / f"{prefix}_{timestamp}.wav")


def run_custom_voice(args):
    """CustomVoice 模式：使用内置音色"""
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
    print("🎵 Qwen3-TTS MLX - CustomVoice 模式")
    print("=" * 50)
    print(f"模型: {model}")
    print(f"文本: {args.text[:50]}{'...' if len(args.text) > 50 else ''}")
    print(f"Voice: {args.voice}")
    print(f"语言: {args.lang_code}")
    if args.instruct:
        print(f"情感: {args.instruct}")
    print(f"输出: {output_path}")
    print("-" * 50)

    result = subprocess.run(cmd)

    if result.returncode == 0:
        print(f"\n✅ 已保存: {output_path}")
    else:
        print(f"\n❌ 生成失败")
        sys.exit(1)


def run_voice_design(args):
    """VoiceDesign 模式：设计自定义音色"""
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
    print("🎵 Qwen3-TTS MLX - VoiceDesign 模式")
    print("=" * 50)
    print(f"模型: {model}")
    print(f"文本: {args.text[:50]}{'...' if len(args.text) > 50 else ''}")
    print(f"音色设计: {args.instruct}")
    print(f"输出: {output_path}")
    print("-" * 50)

    result = subprocess.run(cmd)

    if result.returncode == 0:
        print(f"\n✅ 已保存: {output_path}")
    else:
        print(f"\n❌ 生成失败")
        sys.exit(1)


def run_voice_clone(args):
    """VoiceClone 模式：克隆参考音频"""
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
    print("🎵 Qwen3-TTS MLX - VoiceClone 模式")
    print("=" * 50)
    print(f"模型: {model}")
    print(f"文本: {args.text[:50]}{'...' if len(args.text) > 50 else ''}")
    print(f"参考音频: {args.ref_audio}")
    print(f"输出: {output_path}")
    print("-" * 50)

    result = subprocess.run(cmd)

    if result.returncode == 0:
        print(f"\n✅ 已保存: {output_path}")
    else:
        print(f"\n❌ 生成失败")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Qwen3-TTS MLX 语音合成",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # CustomVoice - 使用内置音色
  python run_tts.py custom-voice --text "你好" --voice Vivian --lang_code Chinese

  # VoiceDesign - 设计自定义音色
  python run_tts.py voice-design --text "你好" --instruct "成熟稳重的男性播音员" --lang_code Chinese

  # VoiceClone - 克隆语音
  python run_tts.py voice-clone --text "你好" --ref_audio ref.wav --ref_text "参考文本"
        """
    )

    subparsers = parser.add_subparsers(dest="mode", help="TTS 模式")

    # CustomVoice 子命令
    cv_parser = subparsers.add_parser("custom-voice", help="使用内置音色生成语音")
    cv_parser.add_argument("--text", required=True, help="要合成的文本")
    cv_parser.add_argument("--voice", default="Vivian",
                          choices=["Vivian", "Serena", "Uncle_Fu", "Dylan", "Eric", "Ryan", "Aiden"],
                          help="Voice 名称 (默认: Vivian)")
    cv_parser.add_argument("--lang_code", default="Chinese",
                          choices=["Chinese", "English", "Japanese", "Korean"],
                          help="语言 (默认: Chinese)")
    cv_parser.add_argument("--instruct", help="情感/语气控制 (如: 温柔的语气)")
    cv_parser.add_argument("--model", help="模型名称 (默认: 0.6B-CustomVoice-4bit)")
    cv_parser.add_argument("--speed", type=float, help="语速调整")
    cv_parser.add_argument("--output", help="输出文件名")
    cv_parser.add_argument("--out-dir", default="./outputs", help="输出目录 (默认: ./outputs)")

    # VoiceDesign 子命令
    vd_parser = subparsers.add_parser("voice-design", help="设计自定义音色")
    vd_parser.add_argument("--text", required=True, help="要合成的文本")
    vd_parser.add_argument("--instruct", required=True, help="音色描述 (如: 可爱活泼的萝莉女声)")
    vd_parser.add_argument("--lang_code", default="Chinese",
                          choices=["Chinese", "English", "Japanese", "Korean"],
                          help="语言 (默认: Chinese)")
    vd_parser.add_argument("--model", help="模型名称 (默认: 1.7B-VoiceDesign-5bit)")
    vd_parser.add_argument("--speed", type=float, help="语速调整")
    vd_parser.add_argument("--output", help="输出文件名")
    vd_parser.add_argument("--out-dir", default="./outputs", help="输出目录 (默认: ./outputs)")

    # VoiceClone 子命令
    vc_parser = subparsers.add_parser("voice-clone", help="克隆参考音频的声音")
    vc_parser.add_argument("--text", required=True, help="要合成的文本")
    vc_parser.add_argument("--ref_audio", required=True, help="参考音频文件路径")
    vc_parser.add_argument("--ref_text", required=True, help="参考音频对应的文本")
    vc_parser.add_argument("--model", help="模型名称 (默认: 0.6B-Base-4bit)")
    vc_parser.add_argument("--speed", type=float, help="语速调整")
    vc_parser.add_argument("--output", help="输出文件名")
    vc_parser.add_argument("--out-dir", default="./outputs", help="输出目录 (默认: ./outputs)")

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
