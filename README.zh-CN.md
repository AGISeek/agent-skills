# Agent Skills

这是一个面向 AI 编程助手的技能集合。每个技能以说明文档和脚本的形式扩展 agent 的能力。

技能遵循 Agent Skills 的格式规范。

## 可用技能

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
