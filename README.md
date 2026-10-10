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
  - A SwiftUI closure calls back into AppKit to update the window subtitle.
  - `glassedSheet`, a drop-in replacement for `.sheet` that presents SwiftUI content as a native AppKit sheet (`presentAsSheet`). Content dismisses itself with `@Environment(\.dismissGlassedSheet)`.
- A programmatic `@main` `NSApplicationDelegate` with a minimal main menu (no storyboards or nibs).

## Project layout

```
Package.swift
Sources/GlassDemo/
├── AppDelegate.swift   # App entry point, window, menu
├── ContentView.swift   # Main SwiftUI view: gradient, glass buttons, morphing group
└── SheetView.swift     # Sheet content: form fields and symbol picker
Sources/GlassedSheet/
└── GlassedSheet.swift  # Reusable library: glassedSheet modifier and its AppKit bridge
```

## Using GlassedSheet in another project

`GlassedSheet` is a separate library product of this package. Add the package as a dependency, then:

```swift
import GlassedSheet

.glassedSheet(isPresented: $show) {
    MySheet() // dismiss with @Environment(\.dismissGlassedSheet)
}
```

## Using the app

- **Tap me**: increments the counter and shows the time of the last tap in the window subtitle.
- **Reset**: sets the counter back to zero.
- **Show Sheet**: opens a "New Item" sheet. Enter a name, pick a symbol and press **Create** to see the result in the main view.
- **+ button**: expands the extra glass buttons (star, heart, bolt). Each one also increments the counter.
