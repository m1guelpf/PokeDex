import SwiftUI

struct DialogBox: View {
	var text: String? = nil

	@State private var dialogHeight: CGFloat = 0
	@State private var finishedShowingText = false

	var screenSize: CGSize {
		UIApplication.shared.mainWindow?.screen.bounds.size ?? .zero
	}

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
						.lineLimit(3)
						.minimumScaleFactor(0.9)
						.foregroundStyle(.black)
						.transition(.dialogText {
							finishedShowingText = true
						})
						.font(.custom("PKMN RBYGSC", size: screenSize.width * 0.04))
						.multilineTextAlignment(.leading)
						.id(text)
						.frame(maxWidth: .infinity, alignment: .leading)
				}

				Spacer(minLength: screenSize.width * 0.31)
			}
			.padding(.leading)
			.padding(.vertical)
			.padding(.bottom, 20)
			.frame(minHeight: 100, alignment: .top)
			.onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { dialogHeight = $0 })

			HStack {
				Spacer()

				Image(.trainer)
					.resizable()
					.scaledToFit()
					.frame(width: screenSize.width * 0.5)
					.offset(x: 34)
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
