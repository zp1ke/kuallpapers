# Kuallpapers

**Kuallpapers** is a dynamic wallpaper plugin for KDE Plasma that allows you to schedule wallpaper changes throughout the day. Instead of relying on fixed solar calculations, it gives you complete control to define exactly when each image should appear.

## Features

- **Custom Schedule**: Define unlimited time slots (HH:MM) and assign specific images to them.
- **Default Day-Cycle**: Comes pre-configured with a 12-stage day/night cycle using high-quality defaults.
- **Flexible**: Set it to change every hour, every 30 minutes, or at specific moments like "08:00" for work start and "18:00" for evening relaxation.
- **Scaling Options**: Supports standard Plasma image scaling modes (Crop, Stretch, Fit, Center, Tile).

## Installation

### From Source

1.  Clone the repository:
    ```bash
    git clone https://github.com/zp1ke/kuallpapers.git
    cd kuallpapers
    ```

2.  Install the plugin using `kpackagetool6`:
    ```bash
    kpackagetool6 --type Plasma/Wallpaper --install .
    ```

    *If you are updating an existing installation, use `--upgrade` instead of `--install`.*

3.  Restart Plasma shell to load the new plugin:
    ```bash
    kquitapp6 plasmashell && kstart plasmashell
    ```

## Configuration

1.  Right-click on your desktop and select **Configure Desktop and Wallpaper**.
2.  In the **Wallpaper Type** dropdown, select **Kuallpapers**.
3.  **Schedule Settings**:
    - The plugin comes with a default schedule.
    - You can **Add**, **Remove**, or **Edit** entries in the list.
    - **Time**: Enter the start time in `HH:MM` format (24-hour).
    - **Image**: Select an image file from your system.
4.  **Display Settings**: Choose how the image should scale to fit your screen.

## Default Schedule

The default configuration provides a smooth transition through the day:

| Time | Phase |
| :--- | :--- |
| 06:00 | Early Morning |
| 08:00 | Mid Morning |
| 10:00 | Late Morning |
| 12:00 | Early Afternoon |
| 14:00 | Mid Afternoon |
| 16:00 | Late Afternoon |
| 18:00 | Early Evening |
| 19:30 | Mid Evening |
| 21:00 | Late Evening |
| 22:30 | Early Night |
| 00:00 | Mid Night |
| 04:00 | Late Night |

## Development

If you want to contribute or modify the plugin, you can use the included helper script in `.bin/dev`:

```bash
# Show available commands
.bin/dev help

# Install locally for current user
.bin/dev install

# Install and open settings for testing
.bin/dev test

# Create a release package
.bin/dev package
```

Alternatively, you can use standard KDE tools:

```bash
# Install locally
kpackagetool6 --type Plasma/Wallpaper --upgrade .
```

## License

Licensed under the [Apache License 2.0](LICENSE).
