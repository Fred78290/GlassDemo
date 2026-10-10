# GlassDemo

A small macOS demo showing how to use the **Liquid Glass** APIs of SwiftUI inside a classic **AppKit** app. The app lifecycle, window, menu and sheet are AppKit; the content is SwiftUI hosted via `NSHostingController`.

## Requirements

- macOS 26 (Tahoe) or later
- Swift 6.2 / Xcode 26 or later

## Build and run

```sh
swift run
```

Or open `Package.swift` in Xcode and run the `GlassDemo` scheme.

## What it demonstrates

- **System glass button styles**: `.glass` and `.glassProminent`.
- **Custom glass effects**: `.glassEffect(.regular.interactive(), in: .circle)` with tinting.
- **Morphing glass**: `GlassEffectContainer` with `glassEffectID` and a shared `@Namespace`, so the `+` button morphs into a row of extra buttons.
- **Glass on text fields**: `.glassEffect()` applied to `TextField` and `SecureField`.
- **AppKit ↔ SwiftUI interop**:
  - A SwiftUI view hosted in an `NSWindow` through `NSHostingController` (transparent, full-size-content titlebar).
  - SwiftUI closures call back into AppKit to update the window subtitle.
  - A SwiftUI view presented as a native AppKit sheet (`presentAsSheet`).
- A programmatic `@main` `NSApplicationDelegate` with a minimal main menu (no storyboards or nibs).

## Project layout

```
Package.swift
Sources/GlassDemo/
├── AppDelegate.swift   # App entry point, window, menu, sheet presentation
├── ContentView.swift   # Main SwiftUI view: gradient, glass buttons, morphing group
└── SheetView.swift     # SwiftUI sheet: form fields and symbol picker
```

## Using the app

- **Tap me**: increments the counter and shows the time of the last tap in the window subtitle.
- **Reset**: sets the counter back to zero.
- **Show Sheet**: opens a "New Item" sheet. Enter a name, pick a symbol and press **Create** to see the result in the subtitle.
- **+ button**: expands the extra glass buttons (star, heart, bolt). Each one also increments the counter.
