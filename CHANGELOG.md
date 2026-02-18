# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [2.0.1] - 2026-02-18

### Security (gemini-watermark)

- **Mandatory SHA256 verification** — installer now aborts instead of warning when the checksum file is unavailable, preventing installation of unverified binaries
- **Explicit user consent** — installer prints a third-party disclosure banner and requires interactive confirmation (`y`) before downloading; pass `--yes` to skip in scripts
- **Removed auto-execution** — installer no longer runs the downloaded binary with `--version` immediately after install; a manual verify command is printed instead
- **API response sanitization** — `tag_name` returned by the GitHub Releases API is validated against `^v[0-9]+\.[0-9]+\.[0-9]+` before being interpolated into download URLs, preventing path-traversal via a malicious API response
- **Prioritized source-based install** — `cargo install gemini-watermark-removal` is now the recommended (Option 1) install path; pre-built binary download is Option 2 with an explicit security notice

## [2.0.0] - 2026-02-07

### Added
- **New Skill: gemini-watermark** - Remove visible Gemini AI watermarks from images
  - Mathematically accurate reverse alpha blending algorithm
  - Three-stage watermark detection (Spatial NCC, Gradient NCC, Variance Analysis)
  - Pre-built binaries for macOS (Apple Silicon / Intel), Linux, Windows
  - One-click installer script (no Rust toolchain required)
  - Auto-detect watermark size (48x48 or 96x96 based on image dimensions)
  - Batch processing for directories
  - Supports JPEG, PNG, WebP, BMP formats

## [1.3.1] - 2026-02-05

### Changed
- **libvips-image skill** - Remove internal analysis documents
  - Removed INSTALLATION_ANALYSIS.md (internal development documentation)
  - Removed OPTIMIZATION_RECOMMENDATIONS.md (internal development documentation)

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
