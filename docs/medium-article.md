# Liquid Glass in a macOS Sheet: Why SwiftUI Flattens It and How to Get It Back

*SwiftUI's `.sheet` turns off the glass inside your sheet on macOS 26. A sheet presented by AppKit keeps it. This article shows how that works, and introduces GlassedSheet, a small Swift package that gives you the AppKit version with the `.sheet` API.*

macOS 26 Tahoe brought Liquid Glass to the Mac, and SwiftUI makes it easy to use: `.buttonStyle(.glass)`, `.glassEffect()`, `GlassEffectContainer`, morphing with `glassEffectID`. So you build a small form with glass text fields, a row of glass icon buttons and a prominent glass "Create" button, and it looks great in your window.

Then you put that form in a sheet:

```swift
.sheet(isPresented: $showSheet) {
    NewItemForm()
}
```

and the glass is gone. The buttons and fields render flat.

Your code isn't at fault. On macOS a SwiftUI sheet is already a glass surface, so SwiftUI drops the glass effects of the content inside it to avoid "glass on glass". That's a reasonable default, but sometimes the sheet is exactly where you want the glass: form fields, pickers, the Cancel/Create pair.

In this article I'll show how to keep it. The short version: present the same SwiftUI view as a native AppKit sheet instead of going through SwiftUI's `.sheet`. The long version is a reusable modifier, `glassedSheet`, packaged as a small library in the [GlassDemo](https://github.com/Fred78290/GlassDemo) repository. We'll use it first, then look at how it works.

![The New Item form presented with SwiftUI's .sheet](https://raw.githubusercontent.com/Fred78290/GlassDemo/main/docs/images/system-sheet.png)
*Presented with SwiftUI's `.sheet`: the glass is flattened.*

![The New Item form presented with .glassedSheet](https://raw.githubusercontent.com/Fred78290/GlassDemo/main/docs/images/glass-sheet.png)
*Presented with `.glassedSheet`: the glass is kept.*

## The idea

AppKit can present any view controller as a sheet with `NSViewController.presentAsSheet(_:)`, and any SwiftUI view can become a view controller with `NSHostingController`. Put the two together:

```swift
let sheetController = NSHostingController(rootView: NewItemForm())
window.contentViewController?.presentAsSheet(sheetController)
```

The content now lives in an ordinary hosting controller rather than in a SwiftUI sheet presentation, so its glass modifiers render as they would in any window. Nothing is overridden: the sheet window keeps the system's default appearance, and all the glass comes from your content.

Those two lines prove the point, but you wouldn't want to sprinkle them through an app. You'd lose everything `.sheet` gives you: a binding that drives presentation, `onDismiss`, a way for the content to close itself, Escape to cancel, and content that updates when the parent's state changes. `glassedSheet` puts all of that back behind the familiar API.

## Quick start

### 1. Add the package

The library is the `GlassedSheet` product of the GlassDemo package. In Xcode, choose **File › Add Package Dependencies…**, enter `https://github.com/Fred78290/GlassDemo` and add `GlassedSheet` to your target. In a `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/Fred78290/GlassDemo.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: [.product(name: "GlassedSheet", package: "GlassDemo")]
        )
    ]
)
```

The Liquid Glass APIs only exist on macOS 26, so your deployment target must be macOS 26 too, and you need Xcode 26 (Swift 6.2).

### 2. Replace `.sheet` with `.glassedSheet`

```swift
import GlassedSheet
import SwiftUI

struct ContentView: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") { showSheet = true }
            .buttonStyle(.glass)
            .glassedSheet(isPresented: $showSheet) {
                NewItemForm()
            }
    }
}
```

It has the same shape as `.sheet(isPresented:onDismiss:content:)`, including the optional `onDismiss` closure. There is also an item-driven variant, like `.sheet(item:onDismiss:content:)`:

```swift
@State private var editedItem: Item?   // Item: Identifiable

.glassedSheet(item: $editedItem) { item in
    EditItemForm(item: item)
}
```

Set the item to present the sheet and set it back to `nil` to dismiss it. One difference from `.sheet(item:)`: changing the item while the sheet is open updates the content in place instead of dismissing and re-presenting the sheet.

### 3. Dismiss from inside the sheet

This is the one change your sheet content needs. SwiftUI's `@Environment(\.dismiss)` knows nothing about a sheet presented by AppKit, so it won't close it. Use `dismissGlassedSheet` instead:

```swift
struct NewItemForm: View {
    @Environment(\.dismissGlassedSheet) private var dismiss

    var body: some View {
        Button("Cancel") { dismiss() }
    }
}
```

You call it like a function, the same way as `dismiss`. Outside a glassed sheet it does nothing, so the view still works in a `#Preview`.

### 4. Escape, and when not to close

Escape closes a glassed sheet, as it does a `.sheet`. If the sheet has a Cancel button with `.keyboardShortcut(.cancelAction)`, that button gets Escape first, so your own cancel logic runs.

Sometimes the sheet must stay open, for example while it's saving. With `.sheet` you'd use `interactiveDismissDisabled(_:)`, but that modifier has no effect on a sheet presented by AppKit. Use `glassedSheetDismissDisabled(_:)` instead:

```swift
NewItemForm()
    .glassedSheetDismissDisabled(isSaving)
```

It only blocks Escape: calling `dismissGlassedSheet` or setting the binding to `false` still closes the sheet.

## Building the glass sheet

Now for the part we did all this for. Here is the sheet from the demo app, slightly trimmed (the full version is in `Sources/GlassDemo/SheetView.swift`):

```swift
import GlassedSheet
import SwiftUI

struct SheetView: View {
    var onConfirm: (_ name: String, _ symbol: String) -> Void = { _, _ in }

    @Environment(\.dismissGlassedSheet) private var dismiss

    @State private var name = ""
    @State private var selectedSymbol = "star.fill"
    @Namespace private var glassNamespace

    private let symbols = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Item")
                .font(.title2.weight(.semibold))

            // Glass on a text field.
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .glassEffect()

            // A row of glass icon buttons; the selected one is tinted.
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(symbols, id: \.self) { symbol in
                        let isSelected = symbol == selectedSymbol
                        Button {
                            withAnimation(.bouncy) { selectedSymbol = symbol }
                        } label: {
                            Image(systemName: symbol)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(
                            isSelected
                                ? .regular.tint(.accentColor).interactive()
                                : .regular.interactive(),
                            in: .circle
                        )
                        .glassEffectID(symbol, in: glassNamespace)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(.glass)
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    onConfirm(name, selectedSymbol)
                    dismiss()
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 380)
    }
}
```

A few things are worth pointing out:

- **It's plain SwiftUI.** There's no AppKit code here, and nothing specific to `glassedSheet` apart from the `dismissGlassedSheet` environment value.
- **Prefer the system glass button styles.** `.glass` and `.glassProminent` handle Cancel and Create. Reach for `.glassEffect(_:in:)` only for custom shapes, like the round symbol buttons.
- **Group related glass in a `GlassEffectContainer`.** The symbol buttons share one, so their glass renders together. Each has a `glassEffectID` in a shared `@Namespace`, which lets glass shapes morph into each other when they appear, disappear or change. `.interactive()` makes the glass react to the pointer and to clicks.
- **The sheet sizes itself from its content.** The hosting controller uses `sizingOptions = [.preferredContentSize]`, so `.frame(width: 380)` is what decides the width of the sheet. Give your sheet content a fixed or ideal width.
- **The result leaves through a closure.** `SheetView` reports the new item with `onConfirm` and doesn't know who presented it.

On the presenting side, `ContentView` uses it like this:

```swift
.glassedSheet(isPresented: $showSheet) {
    SheetView { name, symbol in
        withAnimation { lastCreated = "Created “\(name)” (\(symbol))" }
    }
}
```

## The host window

`glassedSheet` presents on the window that contains the view you attach it to, through that window's `contentViewController`. In the demo, AppKit owns the app: an `NSApplicationDelegate` with a `static func main()` builds the window and hosts `ContentView` in an `NSHostingController`:

```swift
let hostingController = NSHostingController(rootView: ContentView())
hostingController.sizingOptions = [.minSize]

window = NSWindow(contentViewController: hostingController)
window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
window.titlebarAppearsTransparent = true
window.makeKeyAndOrderFront(nil)
```

Two requirements follow from this: the host window must have a `contentViewController`, and that controller must not already be presenting another view controller. If either is not met, the sheet isn't shown.

Also remember that glass needs something behind it to be visible. The demo's main window draws a colourful gradient for exactly that reason.

*[Screenshot: the demo's main window, with the gradient, the glass buttons and the expanded `+` group]*

## Under the hood

The whole library is a single file, `Sources/GlassedSheet/GlassedSheet.swift`, of about 350 lines. Here are the parts that matter.

### An invisible anchor to find the window

A SwiftUI view doesn't know which `NSWindow` it's in. To find out, `glassedSheet` adds a hidden `NSViewRepresentable`, `GlassedSheetPresenter`, in the view's `.background`. Its AppKit view reports when it joins a window, and never takes clicks:

```swift
private final class GlassedSheetAnchorView: NSView {
    var onWindowChange: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChange?(window)
    }

    // Never intercept clicks meant for the real content.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
```

When the anchor leaves its window, or the representable is dismantled, the coordinator closes the sheet.

### Never touch AppKit during a SwiftUI update

`updateNSView` runs while SwiftUI is updating views. Presenting a sheet from there, or writing the binding, would modify state during a view update, which SwiftUI warns about and which leads to subtle bugs. So the coordinator only notes that something changed, and does the AppKit work on the next turn of the main actor:

```swift
func scheduleSync() {
    guard !syncScheduled else { return }
    syncScheduled = true
    Task { @MainActor [weak self] in
        guard let self else { return }
        self.syncScheduled = false
        self.sync()
    }
}
```

`sync()` compares the binding with the AppKit state: it presents if `isPresented` is `true` and no sheet is up, and dismisses if it's `false` and one is.

### Presenting

```swift
private func present() {
    // No window yet: viewDidMoveToWindow will trigger another sync.
    guard let hostWindow = anchor?.window,
        let presenter = hostWindow.contentViewController,
        presenter.presentedViewControllers?.isEmpty ?? true
    else { return }

    let sheetController = GlassedSheetHostingController(rootView: makeRoot())
    sheetController.sizingOptions = [.preferredContentSize]
    // … onDisappear and onCancel callbacks, see below

    presenter.presentAsSheet(sheetController)

    self.hostingController = sheetController
    self.presenter = presenter
}
```

`makeRoot()` wraps your content in a small `GlassedSheetRoot` view that injects `dismissGlassedSheet` into the environment. Dismissing is the mirror image, `presenter.dismiss(hostingController)`. There's no `beginSheet`/`endSheet`: view controller presentation provides a lifecycle to hook into, as we'll see.

### Keeping the content live

`.sheet` re-evaluates its content closure when the parent's state changes. To match that, every update of the presenting view rebuilds the root view of the open sheet:

```swift
if let hostingController {
    // Keep the sheet's content up to date with the parent's state.
    hostingController.rootView = makeRoot()
}
```

That's also what lets the `item:` variant update in place.

### One exit door

A sheet can close in several ways: the binding goes to `false`, the content calls `dismissGlassedSheet`, the user presses Escape, or the presenting view goes away. Resetting state and calling `onDismiss` on each of these paths is an easy way to call it twice, or never.

Instead, the sheet's controller is a small `NSHostingController` subclass that reports `viewDidDisappear`, and that callback is the only place where the coordinator cleans up:

```swift
private func didDisappear() {
    hostingController = nil
    presenter = nil
    isDismissing = false
    isDismissDisabled = false

    if parent.isPresented {
        parent.isPresented = false
    }
    parent.onDismiss?()
}
```

Every path ends here, so however the sheet was closed, the binding is reset and `onDismiss` is called from one single place.

### Escape

AppKit doesn't close an attached sheet on Escape (or ⌘W) by itself. Escape travels the responder chain as `cancelOperation(_:)`, so the hosting controller overrides it:

```swift
override func cancelOperation(_ sender: Any?) {
    onCancel?()
}
```

There are two traps here:

1. **Don't call `super`.** `NSResponder` declares `cancelOperation(_:)` without implementing it, and forwarding the call crashes with "unrecognized selector".
2. **With nothing focused, Escape never arrives.** The sheet window is then its own first responder, and the hosting controller isn't in the chain. While the sheet is visible, a local `keyDown` monitor fixes this: when Escape is pressed and the window is its own first responder, it makes the hosting view first responder. It doesn't consume or change the event, which then goes through the normal dispatch.

```swift
escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
    MainActor.assumeIsolated {
        self?.routeEscape(event)
    }
    return event
}
```

Because `cancelOperation` runs after key equivalents, a button with `.keyboardShortcut(.cancelAction)` still gets Escape first. The monitor only acts on events for its own window, so when sheets are stacked, only the top one closes. The coordinator turns `onCancel` into a dismissal, unless the content has disabled it.

### Disabling dismissal

`glassedSheetDismissDisabled(_:)` is a preference that travels up from the content:

```swift
public func glassedSheetDismissDisabled(_ isDisabled: Bool = true) -> some View {
    self
        .interactiveDismissDisabled(isDisabled)
        .preference(key: GlassedSheetDismissDisabledKey.self, value: isDisabled)
}
```

The preference key reduces its values with OR, so any view in the sheet can block Escape. `GlassedSheetRoot` reads it with `onPreferenceChange` and forwards it to the coordinator, which checks it before turning Escape into a dismissal. The modifier also applies `interactiveDismissDisabled`, for the fallback described next.

### A fallback, just in case

The modifier checks `#available(macOS 26.0, *)` and otherwise falls back to a regular `.sheet`, with `dismissGlassedSheet` forwarded to that sheet's own `dismiss`. With the package's `.macOS(.v26)` platform the fallback is never used, but it keeps the API working if you copy the file into a project with a lower deployment target.

### Swift 6 strict concurrency

The package builds in the Swift 6 language mode. The coordinator is `@MainActor`, closures stored by AppKit objects capture `[weak self]`, and AppKit callbacks that run on the main thread (the event monitor, the controller callbacks) enter the main actor with `MainActor.assumeIsolated`.

## Gotchas

- Inside the sheet, use `@Environment(\.dismissGlassedSheet)`, not `\.dismiss`.
- Use `glassedSheetDismissDisabled(_:)`, not `interactiveDismissDisabled(_:)`.
- The host window needs a `contentViewController` that isn't already presenting something. A `glassedSheet` used inside sheet content is fine: it's presented on top, on the sheet's own window.
- Give the sheet content a width or an ideal size: the sheet takes its content's preferred size.
- macOS 26 and Xcode 26 only. Don't lower the deployment target: the glass APIs don't exist below it.

## Try it

```sh
git clone https://github.com/Fred78290/GlassDemo.git
cd GlassDemo
swift run
```

Click **Glass Sheet**, type a name, pick a symbol and press **Create**. Then click **System Sheet**: it opens the same form with SwiftUI's `.sheet`, so you can see the glass flattened side by side. You can also open `Package.swift` in Xcode and run the `GlassDemo` scheme.

*[GIF: opening the sheet, picking a symbol and pressing Create]*

## Wrapping up

Flattening glass in sheets is a sensible default in SwiftUI, but it isn't the only option. Hosting the content in an `NSHostingController` and presenting it with `presentAsSheet` keeps the glass. Most of the work is restoring what `.sheet` gave you for free: a binding, `onDismiss`, self-dismissal, Escape and live content. `glassedSheet` wraps that into a drop-in modifier, so switching an existing sheet takes one line in the presenting view and one environment value in the sheet.

The code is on GitHub: [Fred78290/GlassDemo](https://github.com/Fred78290/GlassDemo). Issues and pull requests are welcome.
