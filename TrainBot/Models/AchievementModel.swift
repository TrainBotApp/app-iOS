import Foundation

// Represents an achievement in the app
struct AchievementModel: Identifiable {
    let id = UUID().uuidString // Unique identifier for the achievement
    var name: String = "" // Name of the achievement (e.g., "First Training")
    var desc: String = "" // Description of the achievement (e.g., "Train the bot for the first time")
    var unlocked: Bool = false // Indicates whether the achievement has been unlocked
    var unlockedDate: Date? // The date when the achievement was unlocked (optional)
}
