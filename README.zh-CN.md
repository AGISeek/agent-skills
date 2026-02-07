# Agent Skills

这是一个面向 AI 编程助手的技能集合。每个技能以说明文档和脚本的形式扩展 agent 的能力。

技能遵循 Agent Skills 的格式规范。

## 可用技能

### gemini-watermark

通过逆向 alpha 混合算法移除 Gemini AI 图像的可见水印。快速、离线、单文件二进制，零运行时依赖。

**适用场景：**
- 移除 Gemini AI 生成图像上的星形/闪烁水印
- 批量处理 Gemini 生成的图像目录
- 发布或分享前清理图像

**特性：**
- 数学精确的逆向 alpha 混合算法
- 三阶段水印检测（自动跳过无水印图像）
- 预编译二进制支持 macOS、Linux、Windows
- 一键安装脚本（无需 Rust 环境）
- 支持 JPEG、PNG、WebP、BMP 格式

### libvips-image

基于 libvips 的高性能图像处理技能。快速、低内存消耗的图像缩放、格式转换、水印添加和批量处理。

**适用场景：**
- 图像缩放、裁剪、生成缩略图
- 格式转换（JPEG、PNG、WebP、AVIF、HEIC）
- 添加水印或文字叠加
- 批量处理大量图像
- 处理大尺寸图像（低内存占用）

**特性：**
- 13 种图像操作（resize、thumbnail、convert、crop、rotate、watermark、composite、adjust、sharpen、blur、flip、grayscale、info）
- 并行批量处理
- 跨平台：macOS、Linux、Windows
- 一键安装脚本，优先使用 uv
- 内存占用比 ImageMagick/PIL 低 10-100 倍

### qwen3-tts-mlx

基于 MLX 的 Qwen3‑TTS 本地语音合成技能，面向 Apple Silicon。支持 CustomVoice、VoiceDesign、VoiceClone，适合离线配音与多语言生成。

**适用场景：**
- 在 Mac 本地生成语音
- 视频旁白、播客、有声书配音
- 需要可控风格或自定义音色

**特性：**
- 内置音色（CustomVoice）
- 自然语言设计音色（VoiceDesign）
- 参考音频克隆（VoiceClone）
- 批量配音脚本

## 安装

```bash
npx skills add AGISeek/agent-skills
```

## 使用

技能安装后会自动可用，agent 会在相关任务中触发使用。

**示例：**
```
生成中文新闻播报男声（本地）
```
```
用 VoiceDesign 设计一个新音色
```

## 目录结构

每个技能包含：
- `SKILL.md` - 技能说明
- `scripts/` - 可选脚本
- `references/` - 可选参考资料

## License

MIT
