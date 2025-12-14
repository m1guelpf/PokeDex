import SwiftUI
import SwiftCSV
import SQLiteData
import UniformTypeIdentifiers

struct SettingsPage: View {
	@State private var isBrowsingFiles = false
	@State private var willDeleteAllData = false
	@Dependency(\.defaultDatabase) private var database

	var body: some View {
		Form {
			Button("Import CSV") { isBrowsingFiles.toggle() }

			Button("Clear Database", role: .destructive) {
				willDeleteAllData.toggle()
			}
			.confirmationDialog("Delete all data?", isPresented: $willDeleteAllData, titleVisibility: .visible) {
				Button("Delete", role: .destructive) {
					withErrorReporting {
						try database.write { db in
							try Pokemon.delete().execute(db)
						}
					}
				}

				Button("Cancel", role: .cancel) {}
			}
		}
		.fileImporter(isPresented: $isBrowsingFiles, allowedContentTypes: [.commaSeparatedText]) { result in
			do { try onFileSelected(result.get()) }
			catch { Logger.app.error("File import error: \(error)", error: error) }
		}
		.navigationTitle("Settings")
	}

	func onFileSelected(_ url: URL) throws {
		if !url.startAccessingSecurityScopedResource() {
			throw NSError(domain: "SettingsPage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Couldn't access file"])
		}

		let csv = try EnumeratedCSV(string: String(data: Data(contentsOf: url), encoding: .utf8)!)
		url.stopAccessingSecurityScopedResource()

		withErrorReporting {
			try database.write { db in
				try Pokemon.insert {
					csv.rows.map { columns in
						Pokemon.Draft(
							id: UUID(),
							name: columns[2],
							dexNumber: Int(columns[1])!,
							notes: columns.dropFirst(3).joined(separator: ","),
							isRegistered: columns[0] == "TRUE"
						)
					}
				}.execute(db)
			}
		}
	}
}

#Preview {
	NavigationStack {
		SettingsPage()
	}
}
