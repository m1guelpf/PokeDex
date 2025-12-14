import GRDB
import Foundation

final class CreatePokemonTable: Migration {
	static func run(_ db: Database) throws {
		try db.create(table: "pokemon", options: .strict) { table in
			table.id()
			table.column("name", .text).notNull()
			table.column("dexNumber", .integer).notNull()
			table.column("notes", .text).notNull()
			table.column("isRegistered", .integer).notNull().defaults(to: false)
			table.column("isTradeAchievement", .integer).notNull().defaults(to: false)
		}
	}
}
