import Foundation

extension JSONEncoder {
	static let `default`: JSONEncoder = tap(JSONEncoder()) { encoder in
		encoder.dateEncodingStrategy = .iso8601
	}
}

extension JSONDecoder {
	static let `default` = tap(JSONDecoder()) { decoder in
		decoder.dateDecodingStrategy = .iso8601
	}
}
