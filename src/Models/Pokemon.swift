import SwiftUI
import Foundation
import SQLiteData

@Table("pokemon")
struct Pokemon: Identifiable, Equatable, Hashable, Sendable {
	var id: UUID
	var name: String
	var dexNumber: Int
	var notes: String
	var isRegistered: Bool = false

	var imageName: String {
		name.lowercased()
			.replacing("'", with: "")
			.replacing("♂", with: "-m")
			.replacing("♀", with: "-f")
			.replacing(". ", with: "-")
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	func update(set updates: (inout Updates<Pokemon>) -> Void) {
		@Dependency(\.defaultDatabase) var database

		withErrorReporting {
			try database.write { db in
				try Pokemon.find(id).update(set: updates).execute(db)
			}
		}
	}
}

extension Pokemon {
	static let sampleData = Pokemon(
		id: UUID(),
		name: "Larvitar",
		dexNumber: 246,
		notes: "Found in Sevault Canyon.",
		isRegistered: false
	)
}
