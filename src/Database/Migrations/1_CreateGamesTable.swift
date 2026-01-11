import GRDB
import Foundation

final class CreateGamesTable: Migration {
	static func run(_ db: Database) throws {
		try db.create(table: "games", options: .strict) { table in
			table.id()
			table.column("slug", .text).notNull()
			table.column("name", .text).notNull()
			table.column("generation", .integer).notNull()
			table.column("totalPokemon", .integer).notNull()
			table.column("selectedStarter", .text)
			table.column("dataVersion", .text).notNull()
			table.column("spriteURLTemplate", .text).notNull()
			table.column("createdAt", .integer).notNull()
		}
	}
}
