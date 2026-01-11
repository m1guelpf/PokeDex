import Foundation

fileprivate let gameManifestURL = Bundle.main.url(forResource: "games", withExtension: "json")!

struct GameManifest: Equatable, Codable, Sendable {
	struct Game: Equatable, Codable, Sendable {
		struct Pokemon: Equatable, Codable, Sendable {
			let name: String
			let notes: String
			let dexNumber: Int
			let spriteSlug: String
			let excludedForStarters: [String]

			func isAvailable(forStarter starter: String) -> Bool {
				!excludedForStarters.contains(starter)
			}
		}

		let slug: String
		let name: String
		let generation: Int
		let pokemon: [Pokemon]
		let hasStarterChoice: Bool
		let spriteGeneration: String
		let availableStarters: [String]
	}

	let version: String
	let games: [Game]

	static func load() throws -> Self {
		return try JSONDecoder.default.decode(GameManifest.self, from: Data(contentsOf: gameManifestURL))
	}
}
