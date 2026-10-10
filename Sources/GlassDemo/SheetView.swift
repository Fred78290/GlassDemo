import GlassedSheet
import SwiftUI

/// SwiftUI content shown inside a `glassedSheet`.
struct SheetView: View {
	var onConfirm: (_ name: String, _ symbol: String) -> Void = { _, _ in }

	@Environment(\.dismissGlassedSheet) private var dismiss

	@State private var name = ""
	@State private var password = ""
	@State private var selectedSymbol = "star.fill"
	@Namespace private var glassNamespace

	private let symbols = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill"]

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("New Item")
				.font(.title2.weight(.semibold))

			TextField("Name", text: $name)
				.textFieldStyle(.roundedBorder).glassEffect()

			SecureField("Password", text: $password)
				.textFieldStyle(.roundedBorder).glassEffect()

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

#Preview {
	SheetView()
}
