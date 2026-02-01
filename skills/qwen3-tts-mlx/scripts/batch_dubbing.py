#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Qwen3-TTS MLX 批量配音脚本
专为 Apple Silicon (M1/M2/M3/M4) 优化

依赖安装：
    pip install mlx-audio soundfile numpy

使用示例：
    python batch_dubbing.py --input dubbing.json --out-dir outputs
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime


# 默认模型
DEFAULT_MODEL = "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-4bit"


def load_dubbing_script(input_path: str) -> list:
    """加载配音稿 JSON"""
    with open(input_path, "r", encoding="utf-8") as f:
        return json.load(f)


def generate_segment(text: str, voice: str, lang_code: str, instruct: str,
                    output_path: str, model: str) -> bool:
    """生成单个语音片段"""
    cmd = [
        sys.executable, "-m", "mlx_audio.tts.generate",
        "--model", model,
        "--text", text,
        "--voice", voice,
        "--lang_code", lang_code,
        "--output_path", output_path,
    ]

    if instruct:
        cmd.extend(["--instruct", instruct])

    result = subprocess.run(cmd, capture_output=True)
    return result.returncode == 0


def merge_audio_files(segment_files: list, output_path: str,
                     silence_gap: float, character_switch_gap: float,
                     speakers: list) -> bool:
    """使用 FFmpeg 合并音频文件"""
    import tempfile

    # 创建 FFmpeg 输入文件列表
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        prev_speaker = None
        for i, (seg_file, speaker) in enumerate(zip(segment_files, speakers)):
            f.write(f"file '{seg_file}'\n")

            # 添加静音
            if i < len(segment_files) - 1:
                gap = character_switch_gap if prev_speaker and prev_speaker != speaker else silence_gap
                # FFmpeg 需要静音文件，这里用 anullsrc 生成
                f.write(f"file 'anullsrc=r=24000:cl=mono:d={gap}'\n")

            prev_speaker = speaker

        list_file = f.name

    # 简化版：直接拼接（不加静音）
    cmd = [
        "ffmpeg", "-y", "-f", "concat", "-safe", "0",
        "-i", list_file,
        "-c", "copy", output_path
    ]

    # 尝试简单拼接
    try:
        import numpy as np
        import soundfile as sf

        all_audio = []
        sample_rate = 24000

        for i, (seg_file, speaker) in enumerate(zip(segment_files, speakers)):
            audio, sr = sf.read(seg_file)
            all_audio.append(audio)

            # 添加静音
            if i < len(segment_files) - 1:
                gap = character_switch_gap if prev_speaker and prev_speaker != speaker else silence_gap
                silence = np.zeros(int(sample_rate * gap), dtype=np.float32)
                all_audio.append(silence)

            prev_speaker = speaker

        final_audio = np.concatenate(all_audio)
        sf.write(output_path, final_audio, sample_rate)
        return True
    except Exception as e:
        print(f"合并失败: {e}")
        return False


def run_batch_dubbing(args):
    """批量生成配音"""
    # 加载配音稿
    print(f"📄 加载配音稿: {args.input}")
    segments = load_dubbing_script(args.input)
    print(f"   共 {len(segments)} 个片段")

    # 准备输出目录
    out_dir = Path(args.out_dir).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    segments_dir = out_dir / "segments"
    segments_dir.mkdir(exist_ok=True)

    model = args.model or DEFAULT_MODEL
    print(f"🔄 使用模型: {model}")

    segment_files = []
    speakers = []

    for i, seg in enumerate(segments):
        text = seg.get("text", "")
        voice = seg.get("voice", seg.get("speaker", "Vivian"))  # 兼容 speaker 字段
        lang_code = seg.get("lang_code", seg.get("lang", "Chinese"))  # 兼容 lang 字段
        instruct = seg.get("instruct", "")

        print(f"\n🎙️ [{i+1}/{len(segments)}] 生成: {text[:30]}...")
        print(f"   Voice: {voice}, 情感: {instruct or '默认'}")

        # 生成语音
        segment_path = segments_dir / f"seg_{i+1:03d}_{voice}.wav"
        success = generate_segment(
            text=text,
            voice=voice,
            lang_code=lang_code,
            instruct=instruct,
            output_path=str(segment_path),
            model=model
        )

        if success:
            segment_files.append(str(segment_path))
            speakers.append(voice)
            print(f"   ✅ 已保存: {segment_path.name}")
        else:
            print(f"   ❌ 生成失败")

    if not segment_files:
        print("\n❌ 没有成功生成任何片段")
        return

    # 合并音频
    print(f"\n🔗 合并 {len(segment_files)} 个片段...")
    input_stem = Path(args.input).stem.replace(".dubbing", "")
    final_path = out_dir / f"{input_stem}_final.wav"

    success = merge_audio_files(
        segment_files=segment_files,
        output_path=str(final_path),
        silence_gap=args.silence_gap,
        character_switch_gap=args.character_switch_gap,
        speakers=speakers
    )

    if success:
        print(f"\n✅ 完成!")
        print(f"   片段目录: {segments_dir}")
        print(f"   最终文件: {final_path}")
    else:
        print(f"\n⚠️ 合并失败，但片段文件已保存在: {segments_dir}")

    # 复制配音稿到输出目录
    import shutil
    shutil.copy(args.input, out_dir / Path(args.input).name)

    # 清理中间文件
    if args.clean_segments and success:
        print(f"🧹 清理中间片段...")
        shutil.rmtree(segments_dir)


def main():
    parser = argparse.ArgumentParser(
        description="Qwen3-TTS MLX 批量配音",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
配音稿 JSON 格式:
  [
    {"text": "第一段内容", "voice": "Vivian", "lang_code": "Chinese", "instruct": "叙述性语气"},
    {"text": "第二段内容", "voice": "Ryan", "lang_code": "English", "instruct": "兴奋的语气"}
  ]

示例:
  python batch_dubbing.py --input article.dubbing.json --out-dir outputs
        """
    )

    parser.add_argument("--input", required=True, help="配音稿 JSON 文件路径")
    parser.add_argument("--out-dir", default="./outputs", help="输出目录 (默认: ./outputs)")
    parser.add_argument("--model", help=f"模型名称 (默认: {DEFAULT_MODEL})")
    parser.add_argument("--silence-gap", type=float, default=0.3,
                       help="普通段落间静音秒数 (默认: 0.3)")
    parser.add_argument("--character-switch-gap", type=float, default=0.5,
                       help="角色切换时静音秒数 (默认: 0.5)")
    parser.add_argument("--clean-segments", action="store_true",
                       help="合并后删除中间片段文件")

    args = parser.parse_args()

    print("=" * 50)
    print("🎬 Qwen3-TTS MLX 批量配音")
    print("=" * 50)

    run_batch_dubbing(args)


if __name__ == "__main__":
    main()
