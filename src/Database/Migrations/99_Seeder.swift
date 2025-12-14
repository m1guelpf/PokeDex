import Foundation
import SQLiteData

#if DEBUG
final class SeedDatabase: Seeder {
	static func seed() -> Records {
		apply([
			seedPokemon,
		])
	}

	static func seedPokemon() -> [Pokemon] {
		[
			Pokemon.sampleData,
		]
	}
}
#endif
