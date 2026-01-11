import Foundation
import SQLiteData
import TinyStorage

@Table
struct Game: Identifiable, Equatable, Hashable, Sendable {
	var id: UUID
	var slug: String
	var name: String
	var generation: Int
	var dataVersion: String
	var spriteURLTemplate: String
	@Column(as: Date.UnixTimeRepresentation.self) var createdAt: Date

	func sprite(for pokemon: Pokemon) -> URL? {
		URL(string: spriteURLTemplate.replacing("{sprite}", with: pokemon.spriteName))
	}

	@MainActor func delete(_ game: Game) {
		@Dependency(\.defaultDatabase) var database

		withErrorReporting {
			try SpriteManager.shared.deleteAll(forGame: game)

			try database.write { db in
				try Game.find(game.id).delete().execute(db)
			}
		}

		if let activeGameID = TinyStorage.retrieve(type: UUID.self, forKey: .activeGameId), activeGameID == game.id {
			TinyStorage.remove(key: .activeGameId)
		}
	}

	static var currentGame: Where<Game> {
		if let activeGameID = TinyStorage.retrieve(type: UUID.self, forKey: .activeGameId) {
			Game.find(activeGameID)
		} else {
			Game.none
		}
	}
}

extension Game {
	static let sampleData = Game(
		id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
		slug: "firered",
		name: "Pokemon FireRed",
		generation: 3,
		dataVersion: "1.0",
		spriteURLTemplate: "https://img.pokemondb.net/sprites/ruby-sapphire/normal/{sprite}.png",
		createdAt: Date()
	)
}
