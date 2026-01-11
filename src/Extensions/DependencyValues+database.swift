import SQLiteData
import Dependencies

extension DependencyValues {
	mutating func bootstrapDatabase() throws {
		defaultDatabase = try appDatabase()
		defaultSyncEngine = try SyncEngine(for: defaultDatabase, tables: Game.self, Pokemon.self)
	}
}
