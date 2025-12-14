import Network
import Foundation

@MainActor @Observable
final class NetworkMonitor {
	private let monitor = NWPathMonitor()
	private let queue = DispatchQueue(label: "Monitor", qos: .background)

	private(set) var isConnected: Bool = false

	init() {
		monitor.pathUpdateHandler = { [weak self] path in
			guard let self else { return }

			Task { @MainActor in
				self.isConnected = path.status == .satisfied
			}
		}

		monitor.start(queue: queue)
	}
}
