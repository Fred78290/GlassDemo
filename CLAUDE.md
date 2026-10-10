# GlassDemo

A small macOS 26 app. An AppKit shell hosts SwiftUI views that use Liquid Glass. It also contains `glassedSheet`, a reusable replacement for SwiftUI's `.sheet` that presents through AppKit.

## Build & run

```sh
swift build
swift run
```

- Swift tools 6.2, Swift 6 language mode (strict concurrency).
- Platform: `.macOS(.v26)` only. Liquid Glass APIs (`glassEffect`, `.buttonStyle(.glass)`, `GlassEffectContainer`, …) are not available when the deployment target is lower, so do not lower it.
- Requires the Xcode 26 / macOS 26 SDK. It does not build on Linux.

## Layout

```
Package.swift
Sources/GlassDemo/
  AppDelegate.swift    // @main entry: NSApplication, menu, main NSWindow hosting ContentView
  ContentView.swift    // main SwiftUI screen: glass buttons, morphing glass group, owns the `showSheet` state
  SheetView.swift      // content presented in a glassedSheet
Sources/GlassedSheet/  // standalone library target (product "GlassedSheet"), no dependency on the demo
  GlassedSheet.swift   // the glassedSheet modifier and its AppKit bridge
```

## Architecture

- **AppKit owns the app.** `AppDelegate` uses `static func main()` instead of a storyboard or SwiftUI `App`. It builds the menu and puts `ContentView` in an `NSHostingController` used as the window's `contentViewController`.
- **SwiftUI → AppKit communication** goes through plain closures passed into the root view (e.g. `ContentView.onAction`). Don't add singletons or NotificationCenter for this.
- **Sheets:** use `.glassedSheet(isPresented:)` or `.glassedSheet(item:)`, not `.sheet`. Sheet content dismisses itself with `@Environment(\.dismissGlassedSheet)`. SwiftUI's `\.dismiss` does not work in these sheets.

## glassedSheet internals (Sources/GlassedSheet/GlassedSheet.swift)

- Lives in its own library target so other packages can depend on it. The demo imports it with `import GlassedSheet`. Keep it free of demo code, and keep the public API `public`.

- `GlassedSheetPresenter` is a hidden `NSViewRepresentable` placed in `.background`. Its anchor view (`GlassedSheetAnchorView`) finds the host window through `viewDidMoveToWindow`, and its `hitTest` returns `nil`.
- The coordinator presents with `presentAsSheet` on the host window's `contentViewController` and dismisses with `presenter.dismiss(_:)`. There is no `beginSheet`/`endSheet`. The sheet controller is a `GlassedSheetHostingController` whose `viewDidDisappear` calls `didDisappear()`: the single place that clears state, sets the binding to `false` and calls `onDismiss`, however the sheet was closed. The host window's `contentViewController` must be set, and it must not already present another view controller.
- All AppKit work is deferred with `scheduleSync()` (a `Task { @MainActor }`), so the modifier never mutates state during a SwiftUI update. Keep it that way.
- While the sheet is open, `hostingController.rootView` is rebuilt on each parent update so the content stays live.
- The sheet content is wrapped in `GlassedSheetRoot`, which injects `dismissGlassedSheet`. `requestDismiss()` sets the binding to `false` and starts the dismissal.
- The `item:` variant maps to the Bool variant. Changing the item while the sheet is open updates the content in place; it does not re-present the sheet.
- The sheet window uses the system's default appearance. Any glass look comes from the sheet content (see `SheetView`).

## Conventions

- Everything UI-related is `@MainActor`. Bridge AppKit completion handlers with `MainActor.assumeIsolated`.
- Use `[weak self]` / `[weak controller]` in closures stored by AppKit objects.
- Glass needs something behind it to be visible. Keep a colorful background in demo screens.
- Group related glass elements in a `GlassEffectContainer`. Use `glassEffectID(_:in:)` with a `@Namespace` when elements appear or disappear, so they morph.
- Prefer the system glass button styles (`.glass`, `.glassProminent`). Use `.glassEffect(... .interactive(), in:)` only for custom shapes.
- Give every new SwiftUI view a `#Preview`.

## Known open points

- Not run interactively yet: check that Escape, Cancel and Create each reset the binding and call `onDismiss` exactly once.
