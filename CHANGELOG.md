# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.0] - 2026-11-05
### Added
- Regression tests for site data decoding.

### Fixed
- Sites whose station isn't reporting (an empty `<currentConditions/>`) no longer fail to decode; `currentConditions` is `nil` and the forecast still loads. Affected ~4% of sites (e.g. Valemount, Williams Lake, Elliot Lake).
- `Location.Name.value` was always `nil` since the move to XMLCoder 0.17; it now decodes the site name.
