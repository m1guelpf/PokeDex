import SwiftUI
import SQLiteData
import TinyStorage

struct GameScreen: View {
	@Binding var currentGameID: UUID

	@State private var query: String = ""
	@State private var isAddingGame = false
	@State private var isPresentingSettings = false

	@TinyStorageItem(.showingPercentage) private var isShowingPercentage = false
	@TinyStorageItem(.showingOnlyMissing) private var showingOnlyMissing = false

	@Dependency(\.defaultDatabase) private var database
	@FetchAll(Game.all, animation: .default) private var games: [Game]
	@FetchAll(Pokemon.none, animation: .default) private var pokemon: [Pokemon]

	init(currentGameID: Binding<UUID>) {
		_currentGameID = currentGameID
		_pokemon = FetchAll(Pokemon.where { $0.gameId == currentGameID.wrappedValue }.order(by: \.dexNumber), animation: .default)
	}

	var currentGame: Game {
		games.first { $0.id == currentGameID }!
	}

	var subtitle: String {
		if isShowingPercentage {
			let percentage = Double(pokemon.filter(\.isRegistered).count) / Double(pokemon.count) * 100
			return String(format: "%.0f%%", percentage)
		}

		return "\(pokemon.filter(\.isRegistered).count) / \(pokemon.count)"
	}

	var filteredPokemon: [Pokemon] {
		pokemon
			.filter { !showingOnlyMissing || !$0.isRegistered }
			.filter {
				query == "" || $0.name.localizedCaseInsensitiveContains(query) || $0.notes.localizedCaseInsensitiveContains(query)
			}
	}

	var body: some View {
		List(filteredPokemon) { pokemon in
			HStack {
				SpriteManager.shared.get(for: pokemon, in: currentGame)
					.resizable()
					.scaledToFit()
					.frame(width: 50)
					.grayscale(pokemon.isRegistered ? 0 : 1)

				VStack(alignment: .leading) {
					Text(pokemon.name)

					Text(pokemon.notes)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.swipeActions {
				Button(pokemon.isRegistered ? "Mark as Missing" : "Mark as Caught", image: .pokeball) {
					pokemon.update { $0.isRegistered = !$0.isRegistered }
				}
				.tint(pokemon.isRegistered ? .red : .green)
			}
		}
		.animation(.default, value: filteredPokemon)
		.searchable(text: $query)
		.searchPresentationToolbarBehavior(.avoidHidingContent)
		.navigationTitle(currentGame.name)
		.navigationSubtitle(subtitle)
		.toolbarTitleDisplayMode(.inlineLarge)
		.sheet(isPresented: $isPresentingSettings) {
			NavigationStack { SettingsPage() }
		}
		.onShake {
			isPresentingSettings = true
		}
		.toolbarTitleMenu {
			Picker("Select Game", selection: $currentGameID) {
				ForEach(games) { game in
					Text(game.name)
						.tag(game.id)
				}
			}

			Button("Add Game", systemImage: "plus") {
				isAddingGame = true
			}
		}
		.toolbar {
			ToolbarItem(placement: .largeSubtitle) {
				Button(action: { isShowingPercentage.toggle() }) {
					Text(subtitle)
						.font(.caption2)
						.foregroundStyle(.secondary)
						.contentTransition(.numericText())
						.animation(.default, value: subtitle)
				}
				.buttonStyle(.plain)
			}

			ToolbarItem {
				Toggle(isOn: $showingOnlyMissing.animation(.default)) {
					Label("Missing Only", systemImage: "line.3.horizontal.decrease.circle")
				}
			}
		}
		.sheet(isPresented: $isAddingGame) {
			NavigationStack {
				GameCreationSheet()
			}
			.presentationDetents([.medium, .large])
		}
	}
}

#Preview {
	let _ = withErrorReporting {
		try prepareDependencies {
			try $0.bootstrapDatabase()
		}
	}

	NavigationStack {
		GameScreen(currentGameID: .constant(Game.sampleData.id))
	}
}
