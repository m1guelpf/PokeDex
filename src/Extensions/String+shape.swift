import SwiftUI

extension String {
	/// Creates a `TextShape` with the given font.
	func shape(font: UIFont) -> TextShape {
		TextShape(font: font, text: AttributedString(self))
	}
}

struct TextShape: Shape, Equatable {
	var font: UIFont
	var text: AttributedString

	var options: CTLineBoundsOptions = [
		.useOpticalBounds,
	]

	init(font: UIFont, text: AttributedString) {
		self.font = font
		self.text = text

		var container = AttributeContainer()
		container[AttributeScopes.UIKitAttributes.FontAttribute.self] = font

		self.text.mergeAttributes(container, mergePolicy: .keepNew)
	}

	func path(in _: CGRect) -> Path {
		let attributedString = NSAttributedString(text)

		let typeSetter = CTTypesetterCreateWithAttributedString(attributedString)
		let line = CTTypesetterCreateLine(typeSetter, CFRangeMake(0, 0))
		let bounds = CTLineGetBoundsWithOptions(line, options)
		let runs = CTLineGetGlyphRuns(line) as! [CTRun]

		let path = CGMutablePath()

		for run in runs {
			let count = CTRunGetGlyphCount(run)

			guard let glyphsPointer = CTRunGetGlyphsPtr(run) else {
				continue
			}

			let positions = CTRunGetPositionsPtr(run)

			var t = CGAffineTransform.identity
			t = t.scaledBy(x: 1, y: -1)
			t = t.translatedBy(x: 0, y: -bounds.maxY)
			t = t.translatedBy(x: -bounds.minX, y: 0)

			for i in 0..<count {
				guard let subpath = CTFontCreatePathForGlyph(font, glyphsPointer[i], nil) else {
					continue
				}

				let m = t.translatedBy(x: positions?[i].x ?? 0, y: 0)

				path.addPath(subpath.normalized(), transform: m)
			}
		}

		return Path(path)
	}

	func sizeThatFits(_: ProposedViewSize) -> CGSize {
		let attributedString = NSAttributedString(text)

		let typeSetter = CTTypesetterCreateWithAttributedString(attributedString)
		let line = CTTypesetterCreateLine(typeSetter, CFRangeMake(0, 0))
		let bounds = CTLineGetBoundsWithOptions(line, options)

		return bounds.size
	}
}

#Preview("TextShape") {
	TextShape(font: .boldSystemFont(ofSize: 32), text: "1 2 3 4 5 6 7 8 9")
		.stroke(.red)
}
