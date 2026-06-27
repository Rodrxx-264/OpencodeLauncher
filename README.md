# OpenCode Launcher

A simple native macOS launcher for opening [OpenCode](https://opencode.ai/) directly inside a selected project folder.

Instead of opening your terminal manually, navigating to a folder, and running `opencode`, this app lets you choose a project folder, keeps recent projects, and launches OpenCode automatically using an available terminal app.

## Preview

<p align="center">
  <img src="./app.png" alt="OpenCode Launcher Screenshot" width="700">
</p>

## Features

* Native macOS app built with SwiftUI
* Choose any project folder from a clean macOS file picker
* Automatically remembers your last selected project
* Shows recent project folders
* Opens OpenCode with one click
* Automatically detects a compatible terminal
* Supports common macOS terminal apps:

  * Ghostty
  * Kitty
  * WezTerm
  * Alacritty
  * iTerm2
  * Terminal.app
* Lightweight and fast
* No Electron, no background services, no unnecessary bloat

## Why?

OpenCode is usually launched from the terminal:

```bash
cd /path/to/project
opencode
```

That works, but doing it repeatedly can be annoying when jumping between projects.

OpenCode Launcher makes that flow faster:

1. Open the app.
2. Choose a project folder.
3. Click **Open**.
4. Start working in OpenCode.

The goal is to keep the workflow simple, native, and fast.

## Requirements

* macOS
* Xcode
* OpenCode installed and available from your shell
* At least one supported terminal app installed

Make sure `opencode` works from your terminal before using the launcher:

```bash
opencode
```

If macOS apps launched from the Dock cannot find `opencode`, the launcher adds common Homebrew paths automatically:

```bash
/opt/homebrew/bin
/usr/local/bin
/usr/bin
/bin
/usr/sbin
/sbin
```

## Supported Terminals

The app automatically chooses the best available terminal using this priority:

1. Ghostty
2. Kitty
3. WezTerm
4. Alacritty
5. iTerm2
6. Terminal.app

macOS does not provide a universal “default terminal” setting like it does for browsers, so the app detects installed supported terminals and picks the best available one.

## Permissions

For most terminals, the app launches the terminal executable directly.

However, for Terminal.app and iTerm2, macOS may require Automation permissions because those apps are controlled through AppleScript.

If macOS asks for permission, allow it.

You may also need to enable it manually:

```text
System Settings → Privacy & Security → Automation
```

Then allow OpenCode Launcher to control Terminal or iTerm2.

For local development, App Sandbox should be disabled:

```text
Target → Signing & Capabilities → App Sandbox → Disabled
```

The app also needs this key in `Info.plist` if Terminal.app or iTerm2 support is enabled:

```text
NSAppleEventsUsageDescription
```

Suggested value:

```text
This app needs to control the selected terminal to open OpenCode inside the project folder.
```

## Project Structure

```text
OpenCode Launcher
├── OpenCodeLauncherApp.swift
└── ContentView.swift
```

The app is intentionally small and simple. The main logic is contained in `ContentView.swift`.

Main responsibilities:

* UI layout
* Folder selection
* Recent project storage
* Terminal detection
* OpenCode launch command
* Error handling

## How It Works

When the user selects a folder, the app saves its path using `@AppStorage`.

Recent projects are stored as a simple newline-separated list.

When the user clicks **Open**, the app:

1. Gets the selected project path.
2. Detects the best available terminal.
3. Builds the command:

```bash
cd '/selected/project/path' && opencode
```

4. Opens the terminal.
5. Runs OpenCode inside that folder.

## Build Instructions

Clone the repository:

```bash
git clone https://github.com/your-username/opencode-launcher.git
cd opencode-launcher
```

Open the project in Xcode:

```bash
open "OpenCode Launcher.xcodeproj"
```

Then build and run:

```text
Command + R
```

To build without running:

```text
Command + B
```

To export the app:

```text
Product → Archive
```

Or for personal use:

```text
Product → Show Build Folder in Finder
```

Then copy:

```text
OpenCode Launcher.app
```

to:

```text
/Applications
```

## Development Notes

This project was made to be simple, readable, and easy to modify.

Some possible future improvements:

* Custom terminal selection
* Drag and drop folder support
* Favorite projects
* Project search
* Custom OpenCode command
* Menu bar mode
* Better app icon
* Automatic update support
* Signed and notarized release builds

## Known Notes

Ghostty may behave differently depending on how it is launched. The current implementation avoids launching `/bin/zsh` directly through Ghostty’s `-e` mode when possible, because that can trigger macOS permission dialogs or cause the window to close unexpectedly.

Terminal.app and iTerm2 support may require Automation permissions.

## Built With

* Swift
* SwiftUI
* AppKit
* macOS native APIs

## License

MIT License

You are free to use, modify, and share this project.

## Author

Created by Rodrigo Imeri.

This app started as a small personal macOS utility to make opening OpenCode faster and cleaner.
