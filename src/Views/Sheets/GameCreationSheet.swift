import SwiftUI
import SQLiteData
import TinyStorage

let manifest = try! GameManifest.load()

struct GameCreationSheet: View {
	enum Stage: Equatable {
		case selectingGame
		case selectingStarter(game: GameManifest.Game)
		case downloading(progress: Double)
		case completed
	}

	@State var selectedStarter: String?
	@State var stage: Stage = .selectingGame
	@FetchAll(Game.all) private var games: [Game]

	var body: some View {
		Group {
			switch stage {
				case .selectingGame:
					List {
						ForEach(manifest.games, id: \.slug) { game in
							GameCard(game: game, stage: $stage)
						}
					}
					.safeAreaPadding()
					.toolbarTitleDisplayMode(.inline)
					.navigationTitle("Choose your game")
					.navigationSubtitle("Select which Pokemon game you're playing")

				case let .selectingStarter(game):
					StarterSelectionView(game: game) { starter in
						Task { await setup(game: game, starter: starter) }
					}

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

				case .completed:
					VStack(spacing: 20) {
						Image(systemName: "checkmark.circle.fill")
							.resizable()
							.scaledToFit()
							.frame(width: 80)
							.foregroundStyle(.green)

						Text("All Set!")
							.font(.largeTitle)
							.fontWeight(.bold)

						Text("Your PokeDex is ready to use")
							.foregroundStyle(.secondary)
					}
					.padding()
			}
		}
	}

	func setup(game gameData: GameManifest.Game, starter: String?) async {
		selectedStarter = starter

		let availablePokemon = gameData.pokemon.filter { pokemon in
			guard let starter = starter else { return true }
			return pokemon.isAvailable(forStarter: starter)
		}

		let game = Game(
			id: UUID(),
			slug: gameData.slug,
			name: gameData.name,
			generation: gameData.generation,
			totalPokemon: availablePokemon.count,
			dataVersion: manifest.version,
			selectedStarter: starter,
			spriteURLTemplate: "https://img.pokemondb.net/sprites/\(gameData.spriteGeneration)/normal/{sprite}.png",
			createdAt: Date()
		)

		let pokemon = availablePokemon.map { pokemonData in
			Pokemon(
				id: UUID(),
				gameId: game.id,
				name: pokemonData.name,
				notes: pokemonData.notes,
				dexNumber: pokemonData.dexNumber,
				isRegistered: false
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

		stage = .completed
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
