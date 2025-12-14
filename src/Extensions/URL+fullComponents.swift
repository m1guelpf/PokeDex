import Foundation

extension URL {
	var fullComponents: [String] {
		guard let scheme else { return [] }

		return absoluteString
			.replacingOccurrences(of: "\(scheme)://", with: "")
			.split(separator: "/")
			.map { String($0) }
	}
}
