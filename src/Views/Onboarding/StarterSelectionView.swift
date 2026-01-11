import SwiftUI

struct StarterSelectionView: View {
	let game: GameManifest.Game
	let onSelectStarter: (String) -> Void

	var body: some View {
		VStack(spacing: 20) {
			Text("Choose Your Starter")
				.font(.largeTitle)
				.fontWeight(.bold)

			Text("This determines which Pokemon you can catch")
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)

			Spacer()

			VStack(spacing: 16) {
				StarterCard(name: "Bulbasaur", type: "Grass") {
					onSelectStarter("bulbasaur")
				}

				StarterCard(name: "Charmander", type: "Fire") {
					onSelectStarter("charmander")
				}

				StarterCard(name: "Squirtle", type: "Water") {
					onSelectStarter("squirtle")
				}
			}

			Spacer()
		}
		.padding()
	}
}

struct StarterCard: View {
	let name: String
	let type: String
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			HStack(spacing: 16) {
				Image(systemName: iconName)
					.resizable()
					.scaledToFit()
					.frame(width: 40)
					.foregroundStyle(typeColor)

				VStack(alignment: .leading, spacing: 4) {
					Text(name)
						.font(.title3)
						.fontWeight(.semibold)
				}

				Spacer()

				Image(systemName: "chevron.right")
					.foregroundStyle(.secondary)
			}
			.padding()
			.frame(maxWidth: .infinity)
			.background(Color(.systemGray6))
			.clipShape(RoundedRectangle(cornerRadius: 12))
		}
		.buttonStyle(.plain)
	}

	private var typeColor: Color {
		switch type.lowercased() {
			case "grass": .green
			case "fire": .orange
			case "water": .blue
			default: .gray
		}
	}

	private var iconName: String {
		switch type.lowercased() {
			case "grass": "leaf.circle.fill"
			case "fire": "flame.circle.fill"
			case "water": "drop.circle.fill"
			default: "questionmark.circle.fill"
		}
	}
}

#Preview {
	StarterSelectionView(game: manifest.games.first!) { _ in }
}
