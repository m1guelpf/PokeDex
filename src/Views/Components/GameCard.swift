import SwiftUI

struct GameCard: View {
	var game: GameManifest.Game
	@Binding var stage: GameCreationSheet.Stage

	var body: some View {
		Button(action: { stage = .selectingStarter(game: game) }) {
			VStack(spacing: 12) {
				Image(.pokeball)
					.resizable()
					.scaledToFit()
					.frame(width: 60)

				VStack(spacing: 4) {
					Text(game.name)
						.font(.title2)
						.fontWeight(.semibold)

					Text("Generation \(game.generation)")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.frame(maxWidth: .infinity)
			.padding(30)
			.background(Color(.systemGray6))
			.clipShape(RoundedRectangle(cornerRadius: 16))
		}
		.buttonStyle(.plain)
	}
}
