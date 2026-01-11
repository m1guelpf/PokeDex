import SQLiteData

extension PrimaryKeyedTable where Self: Identifiable, Self.ID == PrimaryKey {
	func update(set updates: (inout Updates<Self>) -> Void) {
		@Dependency(\.defaultDatabase) var database

		withErrorReporting {
			try database.write { db in
				try Self.find(id).update(set: updates).execute(db)
			}
		}
	}
}
