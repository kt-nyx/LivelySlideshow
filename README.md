# LivelySlideshow

LivelySlideshow is a simple Windows tray app that allows you to have "slideshow" functionality with [Lively Wallpaper](https://github.com/rocksdanister/lively). This allows you to rotate both "live" and normal wallpapers from a folder on a schedule, just like the Windows "slideshow" wallpaper setting. It supports both regular images and any animated formats that Lively can import, including GIFs and WebP files.

## Requirements

- Windows 10 or Windows 11
- [Lively Wallpaper](https://github.com/rocksdanister/lively)

LivelySlideshow depends on Lively Wallpaper to display wallpapers. If Lively is not installed, the app will show a message telling you where to get it.

## Download

- Download the latest installer from the [GitHub Releases page](https://github.com/kt-nyx/LivelySlideshow/releases/latest).

## Install

1. Install [Lively Wallpaper](https://github.com/rocksdanister/lively).
2. Download `LivelySlideshowSetup.exe` from the [latest release](https://github.com/kt-nyx/LivelySlideshow/releases/latest).
3. Run the installer.
4. The installer places the app in `%LOCALAPPDATA%\LivelySlideshow`.
5. LivelySlideshow will now start automatically and appear in the system tray.

The installer also registers a per-user Task Scheduler entry so the tray app launches silently when you start Windows.

## Uninstall

You can uninstall LivelySlideshow like any other Windows app:

1. Open `Settings` -> `Apps` -> `Installed apps` (or `Apps & features` on older Windows versions).
2. Find `LivelySlideshow`.
3. Click `Uninstall`.

The uninstaller will:

- stop the running tray app
- remove the per-user startup task
- remove the installed app files from `%LOCALAPPDATA%\LivelySlideshow`
- remove LivelySlideshow's local config, state, and log files

If you prefer, you can also run `%LOCALAPPDATA%\LivelySlideshow\unins000.exe` directly.

## Configure

Right-click the tray icon to manage the app:

- `Next wallpaper` changes to the next wallpaper immediately.
- `Shuffle: On/Off` switches between random order and alphabetical order. When shuffle is off, wallpapers rotate alphabetically by filename.
- `Interval` sets how often wallpapers rotate. Preset shortcuts are available, and `Custom...` lets you enter any interval manually in hours.
- `Folder` lets you choose the wallpaper folder.
- `Include subfolders` expands the scan into nested folders (e.g. if you have the folder "Wallpapers" with the folder "Landscapes" inside, the app will also scan through "Landscapes" for wallpapers).

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
- If wallpapers are not changing, check the log file in `%LOCALAPPDATA%\LivelySlideshow\data\logs` for more information.
- If a folder does not work, make sure it contains supported files such as `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, or `.webp`.
- If the tray icon is not present after sign-in, open Task Scheduler and verify the `LivelySlideshow` task exists for your user account.

## License

LivelySlideshow’s own source code is released under the [MIT No Attribution License (MIT-0)](https://opensource.org/licenses/MIT-0) (`LICENSE`). You may use, copy, modify, merge, publish, distribute, sublicense, and/or sell it without preserving a copyright or permission notice in copies.

Third-party components (below) are not covered by MIT-0. The full text of GPLv3 is bundled as `third_party_licenses/LICENSE` because the installer distributes `livelycu.exe` under that license.

## Third-party notices

### Lively Wallpaper (`livelycu.exe`)

LivelySlideshow talks to the user’s installation of [Lively Wallpaper](https://github.com/rocksdanister/lively). The installer downloads `livelycu.exe` (the Lively command utility) from Lively’s release artifacts. That executable is licensed under **GPL-3.0**; the full text is in `third_party_licenses/LICENSE`. Corresponding source for Lively, including the command utility, is available from the [Lively repository](https://github.com/rocksdanister/lively).

### Tray icon (`tray.ico`)

The system tray icon is from Flaticon’s icon set. [Art icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/art)
