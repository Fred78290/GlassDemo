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
  ContentView.swift    // main SwiftUI screen: glass buttons, morphing glass group, presents SheetView with `.sheet` and `glassedSheet` side by side
  SheetView.swift      // content presented in a glassedSheet
Sources/GlassedSheet/  // standalone library target (product "GlassedSheet"), no dependency on the demo
  GlassedSheet.swift   // the glassedSheet modifier and its AppKit bridge
```

## Architecture

- **AppKit owns the app.** `AppDelegate` uses `static func main()` instead of a storyboard or SwiftUI `App`. It builds the menu and puts `ContentView` in an `NSHostingController` used as the window's `contentViewController`.
- **SwiftUI → AppKit communication** goes through plain closures passed into the root view (e.g. `ContentView.onAction`). Don't add singletons or NotificationCenter for this.
- **Why not `.sheet`:** by default a SwiftUI `.sheet` on macOS drops the glass effect of its content to avoid glass on glass. `glassedSheet` exists to keep glass inside sheets.
- **Sheets:** use `.glassedSheet(isPresented:)` or `.glassedSheet(item:)`, not `.sheet` (the demo's **System Sheet** button is the one deliberate `.sheet`, for comparison; it wraps the content in `SystemSheetRoot` so `dismissGlassedSheet` still works). Sheet content dismisses itself with `@Environment(\.dismissGlassedSheet)`. SwiftUI's `\.dismiss` does not work in these sheets.
  Escape also dismisses a glassed sheet. To prevent that (e.g. while saving), use `.glassedSheetDismissDisabled(_:)`: `.interactiveDismissDisabled(_:)` has no effect on an AppKit-hosted sheet.
  Outside a `glassedSheet`, the default value of `dismissGlassedSheet` does nothing (see the `@Entry` in `GlassedSheet.swift`).

## glassedSheet internals (Sources/GlassedSheet/GlassedSheet.swift)

- Lives in its own library target so other packages can depend on it. The demo imports it with `import GlassedSheet`. Keep it free of demo code, and keep the public API `public`.

- `GlassedSheetPresenter` is a hidden `NSViewRepresentable` placed in `.background`. Its anchor view (`GlassedSheetAnchorView`) finds the host window through `viewDidMoveToWindow`, and its `hitTest` returns `nil`.
- The coordinator presents with `presentAsSheet` on the host window's `contentViewController` and dismisses with `presenter.dismiss(_:)`. There is no `beginSheet`/`endSheet`. The sheet controller is a `GlassedSheetHostingController` whose `viewDidDisappear` calls `didDisappear()`: the single place that clears state, sets the binding to `false` and calls `onDismiss`, however the sheet was closed. The host window's `contentViewController` must be set, and it must not already present another view controller.
- `sizingOptions`: the sheet's hosting controller uses `[.preferredContentSize]` and the main window's (in `AppDelegate`) uses `[.minSize]`. Don't switch either to the default `.standardBounds` or add `.intrinsicContentSize`: those constraints fight the window frame and can trigger AppKit's "needing another Update Constraints in Window pass" exception (hang or crash). For the same reason, sheet content needs a fixed width or ideal size and must not size itself from its container.
- All AppKit work is deferred with `scheduleSync()` (a `Task { @MainActor }`), so the modifier never mutates state during a SwiftUI update. Keep it that way.
- While the sheet is open, `hostingController.rootView` is rebuilt on each parent update so the content stays live.
- The sheet content is wrapped in `GlassedSheetRoot`, which injects `dismissGlassedSheet`. `requestDismiss()` sets the binding to `false` and starts the dismissal.
- **Escape.** AppKit never closes an attached sheet by itself (Escape and ⌘W are ignored), so `GlassedSheetHostingController` overrides `cancelOperation(_:)` and calls `onCancel`. The coordinator turns that into `requestDismiss()` unless dismissal is disabled. `cancelOperation` runs after key equivalents, so a button with `.keyboardShortcut(.cancelAction)` (like `SheetView`'s Cancel) still gets Escape first.
  Never call `super.cancelOperation(_:)`: `NSResponder` declares it without implementing it, and forwarding crashes with "unrecognized selector".
- With nothing focused, the sheet window is its own first responder and Escape never reaches `cancelOperation(_:)`. While the sheet is visible, a local `keyDown` monitor makes the hosting view first responder when Escape is pressed. It doesn't consume or change the event.
- `glassedSheetDismissDisabled(_:)` sets the `GlassedSheetDismissDisabledKey` preference (OR-reduced), which `GlassedSheetRoot` forwards to the coordinator's `isDismissDisabled`. It also applies `interactiveDismissDisabled(_:)`, for the `.sheet` fallback.
- The `.sheet` fallback (macOS < 26, unreachable with this package's `.macOS(.v26)` platform) wraps the content in `GlassedSheetFallbackRoot`, which forwards `dismissGlassedSheet` to the sheet's own `@Environment(\.dismiss)`.
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

- Not run interactively yet: check that Cancel and Create each reset the binding and call `onDismiss` exactly once.
  Escape was checked with a scripted test that sends synthesized key events: it resets the binding and calls `onDismiss` once, `glassedSheetDismissDisabled` blocks it, a `.cancelAction` button takes precedence, and only the top sheet of a stack closes. Synthesized key events are only delivered while the app is active, so such a test fails if it runs in the background.
