import OSLog
import Sentry
import Foundation
import IssueReporting

struct Logger: Sendable {
	static let app = Logger(category: "App")

	private let category: String
	private let logger: os.Logger

	init(category: String) {
		self.category = category
		logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
	}

	private func log(_ message: String, level: SentryLevel, error: (any Error)? = nil) {
		if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
			print("\(level.emoji) [\(category)] \(message)")
		}

		switch level {
			case .debug:
				logger.debug("\(message)")
				#if !DEBUG
				SentrySDK.logger.debug(message)
				#endif
			case .info:
				logger.info("\(message)")
				#if !DEBUG
				SentrySDK.logger.info(message)
				#endif
			case .warning:
				logger.warning("\(message)")
				#if !DEBUG
				SentrySDK.logger.warn(message)
				#endif
			case .error:
				logger.error("\(message)")
				#if !DEBUG
				SentrySDK.logger.error(message)
				if let error { SentrySDK.capture(error: error) }
				#endif
			case .fatal:
				logger.fault("\(message)")
				#if !DEBUG
				SentrySDK.logger.fatal(message)
				if let error { SentrySDK.capture(error: error) }
				#endif
			default:
				logger.info("\(message)")
				#if !DEBUG
				SentrySDK.logger.info(message)
				#endif
		}
	}

	func debug(_ message: String) {
		log(message, level: .debug)
	}

	func info(_ message: String) {
		log(message, level: .info)
	}

	func warning(_ message: String) {
		log(message, level: .warning)
	}

	func error(_ message: String, error: (any Error)? = nil) {
		log(message, level: .error, error: error)
	}

	func fault(_ message: String) {
		log(message, level: .fatal)
	}
}

extension SentryLevel {
	var emoji: String {
		switch self {
			case .debug: "🐛"
			case .error: "❗️"
			case .fatal: "💀"
			case .warning: "⚠️"
			case .none, .info: "ℹ️"
			@unknown default: "ℹ️"
		}
	}
}

struct OSLogIssueReporter: IssueReporter {
	func reportIssue(_ message: @autoclosure () -> String?, fileID _: StaticString, filePath: StaticString, line: UInt, column _: UInt) {
		Logger.app.error(message() ?? "Unexpected developer error in \(filePath):\(line)")
	}

	func reportIssue(_ error: any Error, _ message: @autoclosure () -> String?, fileID _: StaticString, filePath: StaticString, line: UInt, column _: UInt) {
		Logger.app.error(message() ?? "Unexpected developer error  in \(filePath):\(line)", error: error)
	}
}
