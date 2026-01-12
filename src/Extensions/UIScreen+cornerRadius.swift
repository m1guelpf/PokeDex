import UIKit
import ObfuscateMacro

public extension UIScreen {
	var displayCornerRadius: CGFloat {
		guard let cornerRadius = value(forKey: #ObfuscatedString("_displayCornerRadius")) as? CGFloat else {
			return 0
		}
		return cornerRadius
	}
}
