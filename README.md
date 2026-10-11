# GlassDemo

A small macOS demo showing how to use the **Liquid Glass** APIs of SwiftUI inside a classic **AppKit** app. The app lifecycle, window, menu and sheet are AppKit; the content is SwiftUI hosted via `NSHostingController`.

## Goal

The main goal of this project is to get a **Liquid Glass effect inside a sheet**. Glass needs something behind it to be visible, and a sheet's content is where you most want it (form fields, icon pickers, Cancel/Create buttons).

By default, a SwiftUI `.sheet` on macOS drops the glass effect of its content, to avoid "glass on glass" (the sheet is already a glass surface). The result is that `.glassEffect`, `.glass` button styles and the like render flat inside a sheet.

To keep the glass, the sheet is presented through AppKit instead of SwiftUI's `.sheet`:

- `glassedSheet` is a drop-in replacement for `.sheet(isPresented:)` and `.sheet(item:)`. It hosts your SwiftUI content in an `NSHostingController` and presents it with AppKit's `presentAsSheet`.
- The sheet content (`SheetView`) then uses the glass APIs directly: `.glassEffect` on text fields, a `GlassEffectContainer` with morphing icon buttons, and `.glass` / `.glassProminent` buttons.
- The logic is packaged as the standalone `GlassedSheet` library, so any SwiftUI view can use it.

For a step-by-step walkthrough of how to use `glassedSheet` and how it works under the hood, read the article [Liquid Glass in a macOS Sheet: Why SwiftUI Flattens It and How to Get It Back](docs/medium-article.md).

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
  - `glassedSheet`, a drop-in replacement for `.sheet` that presents SwiftUI content as a native AppKit sheet (`presentAsSheet`). Content dismisses itself with `@Environment(\.dismissGlassedSheet)`, and Escape dismisses it as with `.sheet`.
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
docs/
└── medium-article.md   # Article: getting a glass sheet with glassedSheet
```

## Using GlassedSheet in another project

`GlassedSheet` is a separate library product of this package. Add the package as a dependency, then:

```swift
import GlassedSheet

.glassedSheet(isPresented: $show) {
    MySheet() // dismiss with @Environment(\.dismissGlassedSheet)
}
```

Escape closes the sheet. To keep it open while the content is busy, use `glassedSheetDismissDisabled` inside the sheet; SwiftUI's `interactiveDismissDisabled` has no effect on an AppKit-hosted sheet:

```swift
MySheetContent()
    .glassedSheetDismissDisabled(isSaving)
```

## Using the app

- **Tap me**: increments the counter and shows the time of the last tap in the window subtitle.
- **Reset**: sets the counter back to zero.
- **Show Sheet**: opens a "New Item" sheet. Enter a name, pick a symbol and press **Create** to see the result in the main view.
- **+ button**: expands the extra glass buttons (star, heart, bolt). Each one also increments the counter.
