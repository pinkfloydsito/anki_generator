# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-01

### Added
- **File Attachment Support**: Attach individual files or entire directories for context-aware flashcard generation
- **Prompt File Support**: Use text files as prompts instead of command-line strings
- **Intelligent File Processing**: Automatic text file detection with support for 20+ file types
- **File Size Management**: Configurable limits (1MB per file, 5MB total) with automatic filtering
- **Enhanced CLI Options**: 
  - `--attach` option for file/directory attachments
  - `--prompt-file` option to read prompts from files
- **Comprehensive Test Suite**: Added `test_file_processor.rb` with full coverage
- **Enhanced Rake Tasks**: 15+ development tasks including demos, examples, and utilities
- **Developer Experience**: 
  - `rake examples` - Create example files for testing
  - `rake demo_attachments` - Demo file attachment features
  - `rake setup` - Full development environment setup

### Enhanced
- **OpenRouter Client**: Extended to support file attachments in AI prompts
- **Anki Generator**: Updated to pass attachments through the generation pipeline
- **CLI Interface**: Both `generate_yaml` and `prompt_to_deck` commands support new options
- **Documentation**: Comprehensive README updates with file attachment examples
- **Error Handling**: Improved file processing with detailed warnings and graceful failures

### Technical
- Added `FileProcessor` class for robust file and directory handling
- Enhanced prompt building with attachment content integration
- Maintained full backward compatibility with existing functionality
- All tests passing (38 tests, 128 assertions)

## [1.0.0] - 2025-12-XX

### Added
- **AI-Powered Generation**: OpenRouter API integration with multiple model support
- **Direct Prompt-to-Deck**: One-command flashcard generation from prompts
- **Multiple Input Methods**: Support for YAML files and direct prompts
- **Sync Functionality**: Merge new AI-generated cards with existing decks
- **Comprehensive CLI**: Full command-line interface with Thor
- **Model Selection**: Support for GPT, Claude, Llama, and other OpenRouter models
- **Difficulty Levels**: Easy, medium, hard difficulty settings
- **Context Support**: Additional context for better AI generation
- **YAML Formats**: Both traditional and AI-generation YAML formats

### Core Features
- `prompt_to_deck` - Generate flashcards and create deck in one step
- `generate_yaml` - Generate YAML from prompts for later use
- `generate` - Create Anki decks from YAML files
- `create_ai_template` - Create template files for AI generation
- `test_api` - Test OpenRouter API connection

### Technical
- Built with Ruby, Thor, Faraday, and anki2 gem
- Comprehensive test suite with minitest
- Environment variable support with dotenv
- Flexible configuration and error handling

## [0.x.x] - Earlier Versions

### Initial Development
- Basic YAML to Anki deck conversion
- Simple flashcard generation
- Core functionality development

---

## Version Numbering

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions  
- **PATCH** version for backwards-compatible bug fixes

## Contributing

When contributing, please:
1. Update this changelog with your changes
2. Follow the existing format and categorization
3. Add entries under "Unreleased" section
4. Move entries to versioned section when releasing