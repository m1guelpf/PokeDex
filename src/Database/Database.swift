import SQLiteData
import Foundation

fileprivate nonisolated let logger = Logger(category: "Database")

func appDatabase() throws -> any DatabaseWriter {
	@Dependency(\.context) var context

	let configuration = tap(Configuration()) { config in
		config.foreignKeysEnabled = true
		config.prepareDatabase { _ in
//			#if DEBUG
//			db.trace(options: .profile) {
//				logger.debug("\($0.expandedDescription)")
//			}
//			#endif
		}
	}

	let database = try defaultDatabase(configuration: configuration)
	if context == .live { logger.info("open '\(database.path)'") }

	var migrator = DatabaseMigrator()
	#if DEBUG
	migrator.eraseDatabaseOnSchemaChange = true
	#endif

	migrator.registerMigrations([
		CreatePokemonTable.self,
	])

	try migrator.migrate(database)

	try database.setupTriggers([
		//
	])

	#if DEBUG
	if context == .preview {
		try database.seed(SeedDatabase.self)
	}
	#endif

	return database
}
