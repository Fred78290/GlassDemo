import SwiftUI

struct ContentView: View {
    /// Called when the main glass button is tapped, so AppKit can react.
    var onAction: () -> Void = {}
    /// Asks AppKit to present the sheet.
    var onShowSheet: () -> Void = {}

    @State private var count = 0
    @State private var showExtras = false
    @Namespace private var glassNamespace

    var body: some View {
        ZStack {
            // Something colourful behind the glass so the effect is visible.
            LinearGradient(
                colors: [.indigo, .purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Tapped \(count) time\(count == 1 ? "" : "s")")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                // 1. Standard system glass button styles.
                HStack(spacing: 16) {
                    Button("Reset") {
                        withAnimation { count = 0 }
                    }
                    .buttonStyle(.glass)

                    Button {
                        withAnimation { count += 1 }
                        onAction()
                    } label: {
                        Label("Tap me", systemImage: "hand.tap.fill")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                    .keyboardShortcut(.defaultAction)

                    Button {
                        onShowSheet()
                    } label: {
                        Label("Show Sheet", systemImage: "rectangle.portrait.on.rectangle.portrait")
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.large)

                // 2. Custom glass buttons that morph into each other.
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 20) {
                        Button {
                            withAnimation(.bouncy) { showExtras.toggle() }
                        } label: {
                            Image(systemName: showExtras ? "xmark" : "plus")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .circle)
                        .glassEffectID("toggle", in: glassNamespace)

                        if showExtras {
                            ForEach(["star.fill", "heart.fill", "bolt.fill"], id: \.self) { symbol in
                                Button {
                                    withAnimation { count += 1 }
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                                .glassEffect(.regular.tint(.white.opacity(0.15)).interactive(), in: .circle)
                                .glassEffectID(symbol, in: glassNamespace)
                            }
                        }
                    }
                }
                .foregroundStyle(.white)
            }
            .padding(40)
        }
        .frame(minWidth: 480, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
