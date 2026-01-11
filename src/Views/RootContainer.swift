import SwiftUI
import SQLiteData
import TinyStorage

struct RootContainer: View {
	@FetchAll(Game.all) private var games: [Game] = []
	@TinyStorageItem(.activeGameId) private var currentGameID: UUID? = nil

	var body: some View {
		Group {
			if games.isEmpty {
				SplashScreen()
			} else {
				if let currentGameID = Binding($currentGameID) {
					GameScreen(currentGameID: currentGameID)
				} else {
					ProgressView()
				}
			}
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

	NavigationStack {
		RootContainer()
	}
}
