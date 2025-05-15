import SwiftUI

// Manages app-wide settings and shared state
class AppSettings: ObservableObject {
    @Published var botName: String = "TrainBot" // The name of the bot, customizable by the user
    @Published var isDarkMode: Bool = false // Tracks whether dark mode is enabled
    @Published var achievementsManager = AchievementsManager() // Manages achievements for the app
}
