import SwiftUI
import Foundation
import SQLiteData

fileprivate nonisolated let logger = Logger(category: "SpriteManager")

@MainActor
class SpriteManager {
	static let shared = SpriteManager()

	private init() {}

	private var imageCache: [String: Image] = [:]

	func get(for pokemon: Pokemon, in game: Game) -> Image {
		let cacheKey = "\(game.slug)-\(pokemon.imageName)"

		if let cached = imageCache[cacheKey] { return cached }

		let filePath = pokemon.spriteFilePath(for: game)

		if FileManager.default.fileExists(atPath: filePath.path), let uiImage = UIImage(contentsOfFile: filePath.path) {
			return tap(Image(uiImage: uiImage)) {
				imageCache[cacheKey] = $0
			}
		} else {
			Task {
				do { try await download(for: pokemon, in: game) }
				catch { logger.error("Failed to download sprite for \(pokemon.name) in fallback: \(error)") }
			}
		}

		return Image(systemName: "questionmark.circle")
	}

	func deleteAll(forGame game: Game) throws {
		let spritesDir = URL.documentsDirectory
			.appendingPathComponent("sprites")
			.appendingPathComponent(game.slug)

		if FileManager.default.fileExists(atPath: spritesDir.path) {
			try FileManager.default.removeItem(at: spritesDir)
		}

		imageCache = imageCache.filter { !$0.key.hasPrefix("\(game.slug)-") }
	}

	func cleanup() throws {
		@Dependency(\.defaultDatabase) var database
		guard let gameSlugs = withErrorReporting(catching: {
			try database.read { db in
				try Game.all.select(\.slug).fetchAll(db)
			}
		}) else { return }

		let gameDirectories = try FileManager.default.contentsOfDirectory(at: URL.documentsDirectory.appendingPathComponent("sprites"), includingPropertiesForKeys: [])

		for directory in gameDirectories {
			let dirName = directory.lastPathComponent
			if gameSlugs.contains(dirName) { continue }

			logger.info("Removing orphaned sprite directory: \(dirName)")
			try FileManager.default.removeItem(at: directory)
			imageCache = imageCache.filter { !$0.key.hasPrefix("\(dirName)-") }
		}
	}
}

// MARK: - Sprite Downloading

extension SpriteManager {
	enum DownloadError: Swift.Error, LocalizedError {
		case downloadFailed(String)
		case invalidSpriteUrl(String)

		var errorDescription: String? {
			switch self {
				case let .invalidSpriteUrl(name): "Invalid sprite URL for \(name)"
				case let .downloadFailed(name): "Failed to download sprite for \(name)"
			}
		}
	}

	struct Progress: Sendable {
		let total: Int
		let failed: Int
		let completed: Int

		var progress: Double {
			guard total > 0 else { return 0 }
			return Double(completed + failed) / Double(total)
		}

		var successRate: Double {
			let processed = completed + failed
			guard processed > 0 else { return 1.0 }
			return Double(completed) / Double(processed)
		}
	}

	nonisolated func download(for pokemon: [Pokemon], in game: Game) throws -> AsyncStream<Progress> {
		try FileManager.default.createDirectory(
			at: URL.documentsDirectory.appending(path: "sprites").appending(path: game.slug),
			withIntermediateDirectories: true
		)

		return AsyncStream { continuation in
			Task {
				var failed = 0
				var completed = 0
				let total = pokemon.count

				logger.debug("Starting sprite download for \(total) pokemon")

				await withTaskGroup(of: (UUID, Bool).self) { group in
					let maxConcurrent = 30
					var activeDownloads = 0

					for poke in pokemon {
						while activeDownloads >= maxConcurrent {
							if let (_, success) = await group.next() {
								activeDownloads -= 1

								if success { completed += 1 }
								else { failed += 1 }

								continuation.yield(Progress(total: total, failed: failed, completed: completed))
							}
						}

						group.addTask {
							do {
								try await self.download(for: poke, in: game)
								return (poke.id, true)
							} catch {
								logger.error("Failed to download sprite for \(poke.name): \(error)")
								return (poke.id, false)
							}
						}
						activeDownloads += 1
					}

					for await (_, success) in group {
						if success { completed += 1 }
						else { failed += 1 }

						continuation.yield(Progress(total: total, failed: failed, completed: completed))
					}
				}

				logger.debug("Sprite download complete: \(completed) succeeded, \(failed) failed")
				continuation.finish()
			}
		}
	}

	@concurrent private nonisolated func download(for pokemon: Pokemon, in game: Game) async throws {
		guard let url = game.sprite(for: pokemon) else {
			throw DownloadError.invalidSpriteUrl(pokemon.imageName)
		}

		let (data, response) = try await URLSession.shared.data(from: url)

		guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
			logger.debug("HTTP error downloading sprite for \(pokemon.name): \((response as? HTTPURLResponse)?.statusCode ?? -1)")
			logger.debug(String(data: data, encoding: .utf8) ?? "No response body")
			throw DownloadError.downloadFailed(pokemon.name)
		}

		try data.write(to: pokemon.spriteFilePath(for: game))
	}
}
