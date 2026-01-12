import SwiftUI

struct LeftRectangleRightCapsule: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()

		let radius = rect.height / 2
		let rightSectionStart = rect.width / 2

		// Start from bottom left
		path.move(to: CGPoint(x: 0, y: rect.height))

		// Left side (straight up)
		path.addLine(to: CGPoint(x: 0, y: 0))

		// Top side where curve starts
		path.addLine(to: CGPoint(x: rightSectionStart, y: 0))

		// Top right curve
		path.addArc(
			center: CGPoint(x: rightSectionStart, y: radius),
			radius: radius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false
		)

		// Bottom side back to the start
		path.addLine(to: CGPoint(x: 0, y: rect.height))

		path.closeSubpath()

		return path
	}
}

#Preview {
	LeftRectangleRightCapsule()
		.fill(.blue)
		.frame(width: 100, height: 50)
}
