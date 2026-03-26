# iStatBar

macOS menu bar CPU / Memory / Disk / Network monitor inspired by iStat Menu.

## Features

- **Menu Bar Display**: Real-time CPU, Memory, Disk, Network stats in menu bar
- **1-Second Updates**: Live monitoring with 1-second refresh rate
- **iStat Menu Style**: Clean, detailed panel view
- **Native Swift**: Built with pure AppKit, no external dependencies

## Requirements

- macOS 13.0+
- Xcode 15+ (for building)
- XcodeGen (for project generation)

## Build

```bash
xcodegen generate
xcodebuild -project iStatBar.xcodeproj -scheme iStatBar -configuration Debug build
```

## Usage

1. Build and run the app
2. See stats in menu bar
3. Click menu bar icon for detailed view

## License

MIT
