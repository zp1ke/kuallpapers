# HEIC Dynamic Desktop Support

Kuallpapers now supports Apple's HEIC Dynamic Desktop format in addition to the flexible JSON schedule format.

## Requirements

To use HEIC files, you need one of these tools installed:
- **ImageMagick** (recommended): `sudo apt install imagemagick` or `brew install imagemagick`
- **exiftool**: `sudo apt install libimage-exiftool-perl` or `brew install exiftool`

Python 3 is also required (usually pre-installed on most systems).

## Usage

### Option 1: Using the UI
1. Open wallpaper settings
2. Click "Browse HEIC" button
3. Select your `.heic` or `.heif` file
4. The wallpaper will automatically extract images and create a schedule

### Option 2: Manual Configuration
Set the `ScheduleJson` configuration to a HEIC file path:
```json
"/path/to/your/dynamic-desktop.heic"
```

## How It Works

1. **Detection**: When a HEIC file path is detected, Kuallpapers automatically processes it
2. **Extraction**: The Python script extracts individual images from the HEIC container
3. **Schedule Creation**: Images are distributed evenly across 24 hours
4. **Caching**: The extracted schedule is cached as `.schedule.json` alongside the HEIC file
5. **Updates**: The wallpaper changes based on the extracted schedule

## Extracted Files

When you select a HEIC file like `mojave.heic`, the following will be created:
- `mojave_00.png`, `mojave_01.png`, etc. (extracted images)
- `mojave.schedule.json` (cached schedule)

These files are stored in a hidden directory: `.mojave_extracted/`

## Example HEIC Files

Popular sources for Dynamic Desktop HEIC files:
- macOS Mojave, Catalina, Big Sur system wallpapers
- Third-party Dynamic Desktop collections

## Fallback to Manual Schedule

If HEIC processing fails (missing dependencies, corrupted file, etc.), you can still use the manual JSON schedule format:

```json
[
  {"time": "00:00", "image": "/path/to/night.jpg"},
  {"time": "06:00", "image": "/path/to/sunrise.jpg"},
  {"time": "12:00", "image": "/path/to/day.jpg"},
  {"time": "18:00", "image": "/path/to/sunset.jpg"}
]
```

## Troubleshooting

### HEIC not processing
Check if ImageMagick is installed:
```bash
magick -version
```

### Permission errors
Ensure the HEIC file and its directory are readable:
```bash
chmod +r /path/to/file.heic
```

### Python not found
Install Python 3 or ensure it's in your PATH.
