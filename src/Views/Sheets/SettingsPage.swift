import SwiftUI
import SQLiteData

struct SettingsPage: View {
	@State private var willDeleteAllData = false
	@Dependency(\.defaultDatabase) private var database
	@FetchOne(Game.currentGame) private var currentGame: Game? = nil

	var body: some View {
		Form {
			if let currentGame {
				Section {
					LabeledContent("Current Game", value: currentGame.name)
				}
			}

			Section {
				Button("Clear Database", role: .destructive) {
					willDeleteAllData.toggle()
				}
				.confirmationDialog("Delete all data?", isPresented: $willDeleteAllData, titleVisibility: .visible) {
					Button("Delete", role: .destructive) {
						withErrorReporting {
							try database.write { db in
								try Game.delete().execute(db)
								try Pokemon.delete().execute(db)
							}
							try SpriteManager.shared.cleanup()
						}
					}

					Button("Cancel", role: .cancel) {}
				}
			}
		}
		.navigationTitle("Settings")
	}
}

#Preview {
	NavigationStack {
		SettingsPage()
	}
}
