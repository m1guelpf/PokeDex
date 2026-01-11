import SwiftUI

struct SplashScreen: View {
	@Namespace var transition
	@State private var showingSheet: Bool = false

	var body: some View {
		VStack(spacing: 30) {
			Spacer()

			Image(.pokeball)
				.resizable()
				.scaledToFit()
				.frame(width: 120)

			VStack(spacing: 10) {
				Text("Welcome to")
					.font(.title2)
					.foregroundStyle(.secondary)

				Text("PokeDex")
					.font(.system(size: 48, weight: .bold))
			}

			Text("Track your Pokemon adventure")
				.font(.title3)
				.foregroundStyle(.secondary)

			Spacer()

			Button("Get Started") {
				showingSheet = true
			}
			.buttonStyle(.borderedProminent)
			.controlSize(.large)
			.matchedTransitionSource(
				id: "sheet", in: transition
			)
		}
		.padding()
		.sheet(isPresented: $showingSheet) {
			NavigationStack {
				GameCreationSheet()
			}
			.presentationDetents([.medium, .large])
			.navigationTransition(.zoom(sourceID: "sheet", in: transition))
		}
	}
}

#Preview {
	SplashScreen()
}
