import SwiftUI

extension Text.Layout {
	/// A helper function for easier access to all runs in a layout.
	var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
		flatMap { $0 }
	}

	/// A helper function for easier access to all run slices in a layout.
	var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
		flattenedRuns.flatMap(\.self)
	}
}
