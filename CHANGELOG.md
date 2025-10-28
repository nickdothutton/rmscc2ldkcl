# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025-10-28

### Added
- Interactive execution mode with user prompts for all parameters
- Batch execution mode for automated/scripted operations
- Two migration modes: staging and complete
- Batch Code parameter for migration tracking
- Customer ID parameter for customer-specific operations
- Secure password input in interactive mode
- Configuration summary and confirmation prompt in interactive mode
- Enhanced parameter validation with detailed error messages
- Mode-specific execution paths (staging vs complete)

### Changed
- Authentication method from API key to basic auth (username/password)
- Parameter structure to support new required fields
- Script version updated to 2.0.0
- README documentation completely rewritten for new structure
- Main execution flow to support interactive and batch modes

### Removed
- API key authentication (replaced with basic auth)
- Source/Target Product ID parameters (replaced with Batch Code and Customer ID)
- Dry-run mode (functionality to be handled by staging mode)

### Security
- Basic authentication with username and password
- Secure password input masking in interactive mode
- HTTPS-only connections recommended
- Sensitive data exclusion in .gitignore

## [1.0.0] - 2025-10-28

### Added
- Initial release of rmscc2ldkcl migration tool
- Core migration functionality from RMS-CloudConnected to LDK-CL
- REST API integration with Thales Sentinel EMS
- Comprehensive logging system with file output
- API connectivity testing
- Error handling and validation
- Command-line parameter support

### Security
- API key authentication support
- HTTPS-only connections recommended
- Sensitive data exclusion in .gitignore

[Unreleased]: https://github.com/nickdothutton/rmscc2ldkcl/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/nickdothutton/rmscc2ldkcl/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/nickdothutton/rmscc2ldkcl/releases/tag/v1.0.0
