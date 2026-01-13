import Foundation
import SQLiteData

#if DEBUG
fileprivate let manifest = try! GameManifest.load()

final class SeedDatabase: Seeder {
	static func seed() -> Records {
		apply([
			seedGame,
			seedPokemon,
		])
	}

	static func seedGame() -> [Game] {
		[Game.sampleData]
	}

	static func seedPokemon() -> [Pokemon] {
		manifest.games.flatMap(\.pokemon).prefix(20).map { pokemon in
			Pokemon(
				id: UUID(),
				gameId: Game.sampleData.id,
				name: pokemon.name,
				spriteName: pokemon.spriteSlug,
				notes: pokemon.notes,
				dexNumber: pokemon.dexNumber
			)
		}
	}
}
#endif
