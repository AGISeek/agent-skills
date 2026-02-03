# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [1.3.0] - 2026-02-04

### Added
- **New Skill: libvips-image** - High-performance image processing with libvips
  - 13 image operations: resize, thumbnail, convert, crop, rotate, watermark, composite, adjust, sharpen, blur, flip, grayscale, info
  - Batch processing with parallel workers and JSON config support
  - Cross-platform one-click installers (install.sh for macOS/Linux, install.ps1 for Windows)
  - Run wrappers that handle library paths (run.sh, run.bat)
  - Prefers **uv** for Python package management
  - Supports JPEG, PNG, WebP, AVIF, HEIC, TIFF, GIF, PDF, SVG formats
  - Streaming architecture for low memory usage (10-100x less than ImageMagick/PIL)

## [1.2.0] - 2026-02-02

### Added
- Support for 11 languages: Chinese, English, Japanese, Korean, French, German, Spanish, Portuguese, Italian, Russian.
- Auto-detect language option (`--lang_code auto`).
- Temperature parameter (`--temperature`) for controlling voice variation.
- Comprehensive voice selection guide and style instruction examples in documentation.
- Performance metrics and troubleshooting table in SKILL.md.

### Changed
- Default language changed from `Chinese` to `auto` (auto-detect).
- Improved CLI help with detailed examples for all three modes.
- Updated SKILL.md with accurate mlx-audio API documentation.
- Enhanced voice and language documentation with character descriptions.

## [1.1.0] - 2026-02-01

### Changed
- Remove broken `configure_transformers()` monkey patch that conflicted with transformers 5.x.
- Use environment variable `TRANSFORMERS_VERBOSITY=error` to suppress warnings instead.
- Fix `--output` flag to output to current directory when only filename is specified.
- Update Python API examples in SKILL.md to use correct `mlx_audio.tts.utils.load` and `generate_audio`.
- Correct CLI parameter documentation (`--model` is optional, not required).

### Removed
- Delete obsolete `qwen3_tts_custom.py` placeholder script.

## [1.0.1] - 2026-02-01

### Changed
- Translate scripts output and CLI text to English.
- Add README.zh-CN.md and link from README.md.
- Add changelog and publish v1.0.1 tag.

## [1.0.2] - 2026-02-01

### Changed
- Use direct Python API in wrapper scripts and enable `fix_mistral_regex` to avoid tokenizer warnings.
- Update SKILL.md examples to use the wrapper scripts.

## [1.0.0] - 2026-02-01

### Added
- Initial Qwen3-TTS MLX skill with scripts and references.
