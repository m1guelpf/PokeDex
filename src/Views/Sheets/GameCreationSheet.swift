import SwiftUI
import SQLiteData
import TinyStorage

fileprivate let manifest = try! GameManifest.load()

struct GameCreationSheet: View {
	enum Stage: Equatable {
		case selectingGame
		case downloading(progress: Double)
	}

	@State var stage: Stage = .selectingGame
	@Environment(\.dismiss) private var dismiss
	@FetchAll(Game.all) private var games: [Game]

	var body: some View {
		Group {
			switch stage {
				case .selectingGame:
					List {
						ForEach(manifest.games, id: \.slug) { game in
							GameCard(game: game) {
								Task { await setup(game: game) }
							}
						}
					}
					.safeAreaPadding()
					.toolbarTitleDisplayMode(.inline)
					.navigationTitle("Choose your game")
					.navigationSubtitle("Select which Pokemon game you're playing")

				case let .downloading(progress):
					VStack(spacing: 30) {
						Spacer()

						Image(.pokeball)
							.resizable()
							.scaledToFit()
							.frame(width: 80)
							.rotationEffect(.degrees(progress * 360))
							.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: progress)

						VStack(spacing: 12) {
							Text("Setting up your PokeDex")
								.font(.title2)
								.fontWeight(.semibold)

							ProgressView(value: progress)
								.frame(maxWidth: 300)

							Text("\(Int(progress * 100))%")
								.font(.caption)
								.foregroundStyle(.secondary)
						}

						Spacer()
					}
					.padding()
					.interactiveDismissDisabled()
			}
		}
	}

	func setup(game gameData: GameManifest.Game) async {
		let game = Game(
			id: UUID(),
			slug: gameData.slug,
			name: gameData.name,
			generation: gameData.generation,
			dataVersion: manifest.version,
			spriteURLTemplate: "https://img.pokemondb.net/sprites/\(gameData.spriteGeneration)/normal/{sprite}.png",
			createdAt: Date()
		)

		let pokemon = gameData.pokemon.map { pokemonData in
			Pokemon(
				id: UUID(),
				gameId: game.id,
				name: pokemonData.name,
				spriteName: pokemonData.spriteSlug,
				notes: pokemonData.notes,
				dexNumber: pokemonData.dexNumber,
				isRegistered: false,
				exclusiveGroup: pokemonData.exclusiveGroup,
				exclusiveOption: pokemonData.exclusiveOption
			)
		}

		stage = .downloading(progress: 0.0)

		await withErrorReporting {
			for await progress in try SpriteManager.shared.download(for: pokemon, in: game) {
				stage = .downloading(progress: progress.progress)
			}
		}

		@Dependency(\.defaultDatabase) var database
		withErrorReporting {
			try database.write { db in
				try Game.insert { game }.execute(db)
				try Pokemon.insert { pokemon }.execute(db)
			}
		}

		dismiss()
	}
}

#Preview {
	@Previewable @State var isPresented = true

	let _ = withErrorReporting {
		try prepareDependencies {
			try $0.bootstrapDatabase()
		}
	}

	VStack {}
		.sheet(isPresented: $isPresented) {
			NavigationStack {
				GameCreationSheet()
			}
			.presentationDetents([.medium, .large])
		}
		.onChange(of: isPresented) { _, newValue in
			guard !newValue else { return }

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				isPresented = true
			}
		}
}
