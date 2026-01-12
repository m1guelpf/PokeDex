import SwiftUI

struct DialogBox: View {
	var text: String? = nil

	@State private var dialogHeight: CGFloat = 0
	@State private var finishedShowingText = false

	var shape: some Shape {
		UnevenRoundedRectangle(
			topLeadingRadius: 20,
			bottomLeadingRadius: UIApplication.shared.mainWindow?.screen.displayCornerRadius ?? 0,
			bottomTrailingRadius: UIApplication.shared.mainWindow?.screen.displayCornerRadius ?? 0,
			topTrailingRadius: 20
		)
	}

	var body: some View {
		ZStack(alignment: .bottom) {
			shape
				.glassEffect(.clear, in: shape)
				.frame(height: dialogHeight)
				.ignoresSafeArea()

			HStack(alignment: .top) {
				if let text {
					Text(AttributedString(text))
						.lineSpacing(7)
						.foregroundStyle(.black)
						.transition(.dialogText {
							finishedShowingText = true
						})
						.font(.custom("PKMN RBYGSC", size: 15))
						.multilineTextAlignment(.leading)
						.id(text)
				}

				Spacer(minLength: 110)
			}
			.padding(.horizontal)
			.padding(.vertical)
			.padding(.bottom, 20)
			.frame(minHeight: 100, alignment: .top)
			.onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { dialogHeight = $0 })

			HStack {
				Spacer()

				Image(.trainer)
					.resizable()
					.scaledToFit()
					.frame(width: 190)
					.offset(x: 20)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
		.onChange(of: text) {
			finishedShowingText = false
		}
	}
}

#Preview {
	DialogBox(text: "My name is Miguel.\nI help the professor with his research.")
		.ignoresSafeArea()
}
