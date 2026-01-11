import Foundation
import SQLiteData

#if DEBUG
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
		[Pokemon.sampleData]
	}
}
#endif
