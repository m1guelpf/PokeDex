import SwiftUI
import SQLiteData
import TinyStorage

struct GameScreen: View {
	var currentGame: Game

	@State private var query: String = ""
	@State private var isAddingGame = false
	@State private var isPresentingSettings = false

	@TinyStorageItem(.activeGameId) private var currentGameID: UUID? = nil
	@TinyStorageItem(.showingPercentage) private var isShowingPercentage = false
	@TinyStorageItem(.showingOnlyMissing) private var showingOnlyMissing = false

	@Dependency(\.defaultDatabase) private var database
	@FetchAll(Game.all, animation: .default) private var games: [Game]
	@FetchAll(Pokemon.none, animation: .default) private var pokemon: [Pokemon]

	init(currentGame: Game) {
		self.currentGame = currentGame
		_pokemon = FetchAll(Pokemon.where { $0.gameId == currentGame.id }.order(by: \.dexNumber), animation: .default)
	}

	var totalCatchablePokemon: Int {
		var count = 0
		var selectedOptions: [String: String] = [:]

		for poke in pokemon {
			guard let group = poke.exclusiveGroup, let option = poke.exclusiveOption else {
				count += 1
				continue
			}

			if selectedOptions[group] == nil { selectedOptions[group] = option }
			if selectedOptions[group] == option { count += 1 }
		}

		return count
	}

	var subtitle: String {
		if isShowingPercentage {
			let percentage = Double(pokemon.filter(\.isRegistered).count) / Double(totalCatchablePokemon) * 100
			return String(format: "%.0f%%", percentage)
		}

		return "\(pokemon.filter(\.isRegistered).count) / \(totalCatchablePokemon)"
	}

	var filteredPokemon: [Pokemon] {
		pokemon
			.filter { !showingOnlyMissing || !$0.isRegistered }
			.filter { poke in
				guard let group = poke.exclusiveGroup, let option = poke.exclusiveOption else {
					return true
				}

				let hasConflictingChoice = pokemon.contains { other in
					other.exclusiveGroup == group && other.exclusiveOption != option && other.isRegistered
				}

				return !hasConflictingChoice
			}
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
		GameScreen(currentGame: .sampleData)
	}
}
