import SwiftUI

struct WithDialogModifier: ViewModifier {
	var lines: [String]
	var shouldShowDialog: Bool = true
	var onDismiss: (() -> Void)? = nil

	@State private var showingDialog = false
	@State private var linesLeft: [String] = []
	@State private var currentLine: String? = nil

	func body(content: Content) -> some View {
		content
			.allowsHitTesting(!showingDialog)
			.overlay {
				ZStack(alignment: .bottom) {
					if showingDialog {
						Color.black.opacity(0.2)
							.transition(.opacity)
							.onDisappear {
								onDismiss?()
								linesLeft = lines
							}
					}

					if showingDialog {
						DialogBox(text: currentLine)
							.transition(.move(edge: .bottom))
					}
				}
				.ignoresSafeArea()
				.allowsHitTesting(showingDialog)
				.onTapGesture {
					guard !linesLeft.isEmpty else {
						withAnimation { showingDialog = false }
						return
					}

					withAnimation(.default.delay(0.2)) {
						currentLine = linesLeft.removeFirst()
					}
				}
			}
			.onChange(of: shouldShowDialog) { _, shouldShow in
				guard shouldShow else {
					withAnimation { showingDialog = false }
					return
				}

				showDialog()
			}
			.onAppear {
				linesLeft = lines

				showDialog()
			}
	}

	func showDialog() {
		guard shouldShowDialog else { return }

		withAnimation(.smooth(duration: 0.5)) {
			showingDialog = true
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
			withAnimation {
				guard !linesLeft.isEmpty else { return }
				currentLine = linesLeft.removeFirst()
			}
		}
	}
}

extension View {
	func withDialog(_ lines: [String], show: Bool = true, onDismiss: (() -> Void)? = nil) -> some View {
		modifier(WithDialogModifier(lines: lines, shouldShowDialog: show, onDismiss: onDismiss))
	}

	func withDialog(_ line: String, show: Bool = true, onDismiss: (() -> Void)? = nil) -> some View {
		modifier(WithDialogModifier(lines: [line], shouldShowDialog: show, onDismiss: onDismiss))
	}
}

#Preview {
	VStack {}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.withDialog([
			"Hey there!\nNice to meet you!",
			"My name is Miguel.\nI'm a Pokemon researcher.",
		])
}
