import SwiftUI

extension AnyTransition {
	/// Animates the appearance of text in a dialog.
	static func dialogText(whenCompleted: (() -> Void)? = nil) -> Self {
		.asymmetric(insertion: AnyTransition(DialogTextTransition(whenCompleted: whenCompleted)), removal: .identity)
	}
}

struct DialogTextTransition: Transition {
	var whenCompleted: (() -> Void)? = nil

	static var properties: TransitionProperties {
		TransitionProperties(hasMotion: true)
	}

	func body(content: Content, phase: TransitionPhase) -> some View {
		let duration = 1.0
		let elapsedTime = phase.isIdentity ? duration : 0
		let renderer = TextAppearRenderer(
			elapsedTime: elapsedTime, totalDuration: duration
		)

		content.transaction { t in
			if !t.disablesAnimations {
				t.animation = .linear(duration: duration)
			}

			t.addAnimationCompletion { whenCompleted?() }
		} body: { view in
			view.textRenderer(renderer)
		}
	}
}

struct TextAppearRenderer: TextRenderer, Animatable {
	/// The amount of time that passes from the start of the animation.
	var elapsedTime: TimeInterval
	/// The amount of time the app spends animating an individual element.
	var elementDuration: TimeInterval
	/// The amount of time the entire animation takes.
	var totalDuration: TimeInterval

	var animatableData: Double {
		get { elapsedTime }
		set { elapsedTime = newValue }
	}

	var spring: Spring {
		.snappy(duration: elementDuration - 0.05)
	}

	init(elapsedTime: TimeInterval, elementDuration: Double = 0.4, totalDuration: TimeInterval) {
		self.totalDuration = totalDuration
		self.elapsedTime = min(elapsedTime, totalDuration)
		self.elementDuration = min(elementDuration, totalDuration)
	}

	func draw(layout: Text.Layout, in context: inout GraphicsContext) {
		let delay = elementDelay(count: layout.flattenedRunSlices.count)

		for (i, slice) in layout.flattenedRunSlices.enumerated() {
			let timeOffset = TimeInterval(i) * delay
			let elementTime = max(0, min(elapsedTime - timeOffset, elementDuration))

			var copy = context
			draw(slice, at: elementTime, in: &copy)
		}
	}

	func draw(_ slice: Text.Layout.RunSlice, at time: TimeInterval, in context: inout GraphicsContext) {
		let progress = time / elementDuration
		let opacity = UnitCurve.easeIn.value(at: 1.4 * progress)
		let transitionY = spring.value(
			fromValue: -slice.typographicBounds.descent + 0.8,
			toValue: 0,
			initialVelocity: 0,
			time: time
		)

//		context.addFilter(.shadow(color: .black, radius: 0.6))
//		context.addFilter(.shadow(color: .black, radius: 0.6))
//		context.addFilter(.shadow(color: .black, radius: 0.6))
//		context.addFilter(.shadow(color: .black, radius: 0.6))

		context.opacity = opacity
		context.translateBy(x: 0, y: transitionY)
		context.draw(slice, options: .disablesSubpixelQuantization)
	}

	func elementDelay(count: Int) -> TimeInterval {
		let count = TimeInterval(count)
		let remainingTime = totalDuration - count * elementDuration

		return max(remainingTime / (count + 1), (totalDuration - elementDuration) / count)
	}
}

#Preview {
	@Previewable @State var showingText = false

	VStack {
		Spacer()

		if showingText {
			Text("Hello, World!")
				.font(.largeTitle)
				.transition(.dialogText())
		}

		Spacer()

		Button("Toggle Text") {
			showingText.toggle()
		}
	}
}
