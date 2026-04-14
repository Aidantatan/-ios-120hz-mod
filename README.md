# iOS 120Hz Mod for Geometry Dash

A Geode mod that unlocks 120Hz ProMotion display support for Geometry Dash on iOS.

## Requirements

- iOS device with ProMotion display (iPhone 13 Pro/Pro Max or later, iPad Pro 2017 or later)
- iOS 15.0+ (uses CAFrameRateRange API)
- Geometry Dash 2.2074
- Geode sideloader installed

## Installation

1. Build the mod using Geode CLI
2. Install the `.geode` file via sideloader
3. Launch Geometry Dash
4. The mod automatically enables 120Hz

## How It Works

The mod hooks into:
- `AppDelegate::applicationDidFinishLaunching()` - Sets up display link with 120Hz
- `CCDirector::setAnimationInterval()` - Forces 120Hz update rate
- `UIViewController` - Configures Metal layer for 120Hz

## Building

```bash
geode build --target ios
```

## Notes

- The mod only works on devices with hardware 120Hz support
- Older devices will still run at 60Hz
- Game physics is decoupled from frame rate via Cocos2d-x's fixed timestep

## License

MIT
