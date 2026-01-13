import Foundation
import TinyStorage

extension TinyStorage {
	enum Keys: String, TinyStorageKey {
		case activeGameId
		case hasSeenOnboarding
		case showingPercentage
		case showingOnlyMissing
	}

	fileprivate static let shared = TinyStorage(insideDirectory: URL.documentsDirectory, name: "prefs")

	static func retrieve<T>(type _: T.Type, forKey key: Keys) -> T? where T: Codable {
		shared.retrieve(type: T.self, forKey: key)
	}

	static func retrieveWithFallback<T>(type: T.Type, forKey key: Keys, fallback: () -> T?) -> T? where T: Codable {
		if let value = retrieve(type: type, forKey: key) { return value }
		guard let fallback = fallback() else { return nil }

		store(fallback, forKey: key)
		return fallback
	}

	static func store<T>(_ value: T?, forKey key: Keys) where T: Codable {
		shared.store(value, forKey: key)
	}

	static func remove(key: Keys) {
		shared.remove(key: key)
	}
}

extension TinyStorageItem {
	init(wrappedValue: T, _ key: TinyStorage.Keys) {
		self.init(wrappedValue: wrappedValue, key, storage: TinyStorage.shared)
	}
}
