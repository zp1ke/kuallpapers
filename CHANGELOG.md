# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.2] - 2026-02-02

### Added
- HEIC image format support with automatic conversion
- Import/Export functionality for schedule settings
- Default wallpaper artwork from bitday.me with 12-stage day/night cycle

### Changed
- Refactored schedule JSON handling with dedicated function for default values
- Enhanced development environment output

### KDE Store Changelog
```
Version 0.0.2 brings new features and improvements:
• Import/Export your schedule settings to easily backup or share configurations
• Beautiful default 12-stage day/night cycle wallpaper artwork included
• Improved schedule handling for better reliability
• Enhanced development tools

This update makes it easier to manage your wallpaper schedules and includes stunning default artwork for every moment of the day.
```

## [0.0.1] - 2026-01-31

### Added
- Initial release of Kuallpapers
- Custom time-based wallpaper scheduling (HH:MM format)
- Unlimited time slots with image assignments
- Standard Plasma image scaling modes (Crop, Stretch, Fit, Center, Tile)
- Configuration UI for managing schedule entries
- Add, remove, and edit schedule entries
- Automatic wallpaper updates based on time schedule
- Development helper script (`.bin/dev`) with commands:
  - `install` - Install plugin locally
  - `test` - Install and open settings
  - `package` - Create release package
  - `release` - Create GitHub release
  - `clean` - Remove temporary files
- Draft and prerelease options for release command
- Complete KDE Plasma 6 plugin structure

### KDE Store Changelog
```
Initial release of Kuallpapers - Dynamic Wallpaper Scheduler for KDE Plasma 6

Features:
• Custom time-based wallpaper scheduling with HH:MM format
• Unlimited time slots - change wallpapers as often as you like
• Easy-to-use configuration interface
• Add, remove, and edit schedule entries on the fly
• Supports all standard Plasma scaling modes (Crop, Stretch, Fit, Center, Tile)
• Automatic wallpaper updates based on your schedule

Perfect for creating dynamic desktop environments that change throughout your day!
```
