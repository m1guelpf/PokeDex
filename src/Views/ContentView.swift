import SwiftUI
import SQLiteData
import TinyStorage

struct ContentView: View {
	@State private var query: String = ""
	@State private var isPresentingSettings = false

	@FetchAll(Pokemon.order(by: \.dexNumber), animation: .default) var pokemon

	@TinyStorageItem(.showingPercentage) private var isShowingPercentage = false
	@TinyStorageItem(.showingOnlyMissing) private var showingOnlyMissing = false

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
				Image(pokemon.imageName)
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
		.navigationTitle("Pokémon")
		.navigationSubtitle(subtitle)
		.toolbarTitleDisplayMode(.inlineLarge)
		.sheet(isPresented: $isPresentingSettings) {
			NavigationStack { SettingsPage() }
		}
		.onShake {
			isPresentingSettings = true
		}
		.toolbar {
			ToolbarItem(placement: .largeSubtitle) {
				Text(subtitle)
					.font(.caption)
					.foregroundStyle(.secondary)
					.contentTransition(.numericText())
					.onTapGesture {
						withAnimation { isShowingPercentage.toggle() }
					}
			}

			ToolbarItem {
				Toggle(isOn: $showingOnlyMissing.animation(.default)) {
					Label("Missing Only", image: .pokeball)
				}
			}
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
		ContentView()
	}
}
