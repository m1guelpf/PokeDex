import SwiftUI
import SQLiteData
import TinyStorage

struct RootContainer: View {
	@FetchAll(Game.all) private var games: [Game] = []
	@State private var showingNewGameDialog: Bool = false
	@TinyStorageItem(.activeGameId) private var currentGameID: UUID? = nil
	@TinyStorageItem(.hasSeenOnboarding) private var hasSeenOnboarding = false

	var currentGame: Game? {
		guard let currentGameID else { return nil }
		return games.first(where: { $0.id == currentGameID })
	}

	var body: some View {
		NavigationStack {
			if games.isEmpty {
				SplashScreen()
			} else {
				if let currentGame {
					GameScreen(currentGame: currentGame, showingNewGameDialog: $showingNewGameDialog)
				} else {
					ProgressView()
				}
			}
		}
		.withDialog([
			"Heading off on a new adventure?",
			"Let me know which region you're off to,",
			"and I'll load all the data we have on it for you.",
		], show: showingNewGameDialog) {
			showingNewGameDialog = false
		}
		.withDialog([
			"Alright!\nI've loaded all the data we have about the region",
			"This includes a list of all known Pokemon, and where to find them.",
			"You can swipe right on any of the entries to mark it as caught,",
			"and filter the list to see which ones you're still missing.",
			"Good luck on your adventure!",
		], show: currentGame != nil && !hasSeenOnboarding) {
			hasSeenOnboarding = true
		}
		.onAppear { repareCurrentGameIfNeeded() }
		.onChange(of: games) { repareCurrentGameIfNeeded() }
		.onChange(of: currentGameID) { repareCurrentGameIfNeeded() }
	}

	func repareCurrentGameIfNeeded() {
		guard let firstGame = games.first else { return }

		if currentGameID == nil || !games.contains(where: { $0.id == currentGameID }) {
			currentGameID = firstGame.id
		}
	}
}

#Preview {
	let _ = withErrorReporting {
		try prepareDependencies {
			try $0.bootstrapDatabase()
		}
	}

	RootContainer()
}
