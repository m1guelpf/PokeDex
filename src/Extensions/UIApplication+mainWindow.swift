import UIKit.UIApplication

extension UIApplication {
	var mainWindow: UIWindow? {
		guard let scene = connectedScenes.first as? UIWindowScene else { return nil }
		return scene.windows.first { $0.isKeyWindow }
	}
}
