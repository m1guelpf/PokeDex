import SwiftUI
import Foundation
import SQLiteData

@Table("pokemon")
struct Pokemon: Identifiable, Equatable, Hashable, Sendable {
	var id: UUID
	var gameId: UUID
	var name: String
	var spriteName: String
	var notes: String
	var dexNumber: Int
	var isRegistered: Bool = false
	var exclusiveGroup: String?
	var exclusiveOption: String?

	func spriteFilePath(for game: Game) -> URL {
		URL.documentsDirectory.appending(path: "sprites").appending(path: game.slug).appending(path: "\(spriteName).png", directoryHint: .notDirectory)
	}
}

extension Pokemon {
	static let sampleData = Pokemon(
		id: UUID(),
		gameId: Game.sampleData.id,
		name: "Larvitar",
		spriteName: "larvitar",
		notes: "Found in Sevault Canyon.",
		dexNumber: 246,
		isRegistered: false
	)
}
