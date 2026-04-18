# LivelySlideshow

LivelySlideshow is a simple Windows tray app that rotates wallpapers from a folder on a schedule by sending each file to Lively Wallpaper. It supports regular images plus animated formats that Lively can import, including GIFs and WebP files.

## Download

- Download the latest installer from the GitHub Releases page.
- Install [Lively Wallpaper](https://github.com/rocksdanister/lively).
- Run `LivelySlideshowSetup.exe`.

## Requirements

- Windows 10 or Windows 11
- [Lively Wallpaper](https://github.com/rocksdanister/lively) installed by the user

LivelySlideshow depends on Lively Wallpaper to display wallpapers. If Lively is not installed, the app will show a message telling you where to get it.

## Install

1. Install [Lively Wallpaper](https://github.com/rocksdanister/lively).
2. Download `LivelySlideshowSetup.exe` from GitHub Releases.
3. Run the installer.
4. The installer places the app in `%LOCALAPPDATA%\LivelySlideshow`.
5. LivelySlideshow starts automatically and appears in the system tray.

The installer also registers a per-user Task Scheduler entry so the tray app launches silently when you sign in.

## Configure

Right-click the tray icon to manage the app:

- `Next wallpaper` changes immediately.
- `Shuffle now` reshuffles the current playlist and changes immediately.
- `Interval` sets how often wallpapers rotate.
- `Folder` lets you choose the wallpaper folder.
- `Include subfolders` expands the scan into nested folders.

Left-clicking the tray icon also changes to the next wallpaper.

## Files And Storage

LivelySlideshow stores its runtime data here:

- Config: `%LOCALAPPDATA%\LivelySlideshow\data\config.json`
- State: `%LOCALAPPDATA%\LivelySlideshow\data\state.json`
- Logs: `%LOCALAPPDATA%\LivelySlideshow\data\logs\LivelySlideshow.log`

The bundled Lively command utility is stored here:

- `%LOCALAPPDATA%\LivelySlideshow\app\livelycu.exe`

## Troubleshooting

- If you see a message about `livelycu.exe` being missing, reinstall LivelySlideshow.
- If you see a message saying Lively Wallpaper is required, install it from [the Lively project page](https://github.com/rocksdanister/lively), then start Lively Wallpaper once.
- If wallpapers are not changing, check the log file in `%LOCALAPPDATA%\LivelySlideshow\data\logs`.
- If a folder does not work, make sure it contains supported files such as `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, or `.webp`.
- If the tray icon is not present after sign-in, open Task Scheduler and verify the `LivelySlideshow` task exists for your user account.

## License

LivelySlideshow’s own source code is released under the [MIT No Attribution License (MIT-0)](https://opensource.org/licenses/MIT-0) (`LICENSE`). You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell it without preserving a copyright or permission notice in copies.

Third-party components (below) are not covered by MIT-0. The full text of GPLv3 is bundled as `LICENSES/GPL-3.0.txt` because the installer distributes `livelycu.exe` under that license.

## Third-party notices

### Lively Wallpaper (`livelycu.exe`)

LivelySlideshow talks to the user’s installation of [Lively Wallpaper](https://github.com/rocksdanister/lively). The installer downloads `livelycu.exe` (the Lively command utility) from Lively’s release artifacts. That executable is licensed under **GPL-3.0-only**; the full text is in `LICENSES/GPL-3.0.txt`. Corresponding source for Lively, including the command utility, is available from the [Lively repository](https://github.com/rocksdanister/lively).

### Tray icon (`tray.ico`)

The system tray icon is derived from Flaticon’s “art” icon set. [Art icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/art)
