# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-23

### Added
- `--version` / `-v` flag to show gem version
- `--help` / `-h` flag to show usage information
- `init` command to generate sample config file
- `--validate` / `--check` flag to validate config syntax without applying
- `--dry-run` flag to preview changes without writing to Karabiner
- `--verbose` flag for detailed output
- `--no-backup` flag to skip automatic config backup
- Automatic config file detection in multiple locations:
  - `$XDG_CONFIG_HOME/karules/config.rb`
  - `~/.config/karules/config.rb`
  - `~/.karules.rb`
  - `./karules.rb`
- Automatic backup of existing Karabiner config before changes
- Success message after config update showing file path
- Better error messages and help text

### Changed
- CLI now uses OptionParser for robust argument handling
- Config file path is now optional (auto-detected)
- Improved error messages when config file not found

## [0.1.0] - 2025-01-23

### Added
- Initial release of KaRules gem
- Ruby DSL for configuring Karabiner-Elements
- Support for keyboard mappings with modifiers
- Support for mouse button mappings
- Application-specific rules with bundle identifiers
- Modal keyboard modes with state management
- Custom Karabiner config path via `karabiner_path` DSL
- XDG Base Directory specification support
- Command-line executable for loading user configs
- Example configuration file
- Comprehensive test suite

### Features
- Simple mapping syntax: `m("from", "to")`
- Modifier support: `+mandatory` and `-optional`
- Shell command execution: `!command`
- Complex conditions and parameters
- Group organization with descriptions
- Deep hash sorting for consistent JSON output

[0.2.0]: https://github.com/dzirtusss/karules/releases/tag/v0.2.0
[0.1.0]: https://github.com/dzirtusss/karules/releases/tag/v0.1.0
