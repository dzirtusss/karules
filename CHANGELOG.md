# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/avsej/karules/releases/tag/v0.1.0
