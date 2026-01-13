import SwiftUI
import SQLiteData
import IssueReporting

@main
struct PocketApp: App {
	init() {
		IssueReporters.current = IssueReporters.current + [OSLogIssueReporter()]

		withErrorReporting {
			try prepareDependencies {
				try $0.bootstrapDatabase()
			}
		}
	}

	var body: some Scene {
		WindowGroup {
			RootContainer()
		}
	}
}
