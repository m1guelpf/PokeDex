import SwiftUI

struct JaggedRectangle: Shape {
	let numberOfJags: Int
	let jaggedHeight: CGFloat

	func path(in rect: CGRect) -> Path {
		var path = Path()

		// Start from bottom left
		path.move(to: CGPoint(x: 0, y: rect.height))

		// Draw left side up to where the jagged edge starts
		path.addLine(to: CGPoint(x: 0, y: jaggedHeight))

		// Create jagged top edge
		let jaggedWidth = rect.width / CGFloat(numberOfJags)

		for i in 0...numberOfJags {
			let x = CGFloat(i) * jaggedWidth
			let clampedX = min(x, rect.width)

			if i % 2 == 0 {
				// Draw jagged peak
				path.addLine(to: CGPoint(x: clampedX, y: 0))
			} else {
				// Draw jagged valley
				path.addLine(to: CGPoint(x: clampedX, y: jaggedHeight))
			}
		}

		// Complete the rectangle
		path.addLine(to: CGPoint(x: rect.width, y: rect.height))
		path.addLine(to: CGPoint(x: 0, y: rect.height))

		path.closeSubpath()

		return path
	}
}

#Preview {
	JaggedRectangle(numberOfJags: 20, jaggedHeight: 20)
		.fill(Color.blue)
		.frame(height: 100)
}
