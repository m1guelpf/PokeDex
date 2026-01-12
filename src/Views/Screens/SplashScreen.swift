import SwiftUI

struct SplashScreen: View {
	@State private var showingSheet: Bool = false

	var body: some View {
		VStack {
			//
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background {
			Image(.introBackground)
				.resizable()
				.scaledToFill()
				.ignoresSafeArea()
		}
		.withDialog([
			"Hi there!\nNice to meet you!",
			"My name is Miguel.\nI help the professor\n with his research.",
			"I've been working on something that'll help with your adventure.",
			"It's a device with data on where you can find all species of Pokémon!",
			"To set it up, I just need to know which region you're heading to.",
		]) { showingSheet = true }
		.sheet(isPresented: $showingSheet) {
			NavigationStack {
				GameCreationSheet()
			}
			.presentationDetents([.medium, .large])
		}
	}
}

#Preview {
	SplashScreen()
}
