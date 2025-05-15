import SwiftUI

// Represents an individual achievement with its properties
struct Achievement: Identifiable, Codable {
    let id = UUID() // Unique identifier for the achievement
    let name: String // Name of the achievement
    let description: String // Description of the achievement
    var unlocked: Bool // Whether the achievement is unlocked
    var unlockedDate: Date? // Date when the achievement was unlocked
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, unlocked, unlockedDate
    }
}

// Manages the achievements system, including unlocking and saving achievements
class AchievementsManager: ObservableObject {
    static let shared = AchievementsManager() // Singleton instance for shared access
    
    @Published var achievements: [Achievement] // List of all achievements
    @Published var showingUnlockAlert = false // Whether to show an unlock alert
    @Published var lastUnlockedAchievement: Achievement? // The last unlocked achievement
    
    init() {
        // Load saved achievements from UserDefaults or initialize default achievements
        if let savedAchievements = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: savedAchievements) {
            self.achievements = decoded
        } else {
            // Default achievements if none are saved
            self.achievements = [
                Achievement(name: "First Training", description: "Train the bot for the first time", unlocked: false),
                Achievement(name: "First Test", description: "Test the bot for the first time", unlocked: false),
                Achievement(name: "Upload 5 Images", description: "Upload five images to train the bot", unlocked: false),
                Achievement(name: "Complete Knowledge", description: "View all knowledge entries", unlocked: false),
            ]
            saveAchievements() // Save the default achievements
        }
    }
    
    // Saves the current achievements to UserDefaults
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }
    
    // Unlocks an achievement by its name
    func unlockAchievement(named name: String) {
        // Find the achievement by name and ensure it is not already unlocked
        if let index = achievements.firstIndex(where: { $0.name == name && !$0.unlocked }) {
            var achievement = achievements[index]
            achievement.unlocked = true // Mark the achievement as unlocked
            achievement.unlockedDate = Date() // Set the unlock date
            achievements[index] = achievement
            saveAchievements() // Save the updated achievements
            
            // Show a notification alert for the unlocked achievement
            lastUnlockedAchievement = achievement
            showingUnlockAlert = true
            
            // Send a congratulation notification for the unlocked achievement
            NotificationManager.shared.sendCongratulationNotification(for: achievement)
        }
    }
    
    // Updates achievements based on specific criteria
    func updateAchievementsAfterChallenge() {
        // Unlock "First Training" if total points are at least 10
        if DailyChallengeManager.shared.totalPoints >= 10 {
            unlockAchievement(named: "First Training")
        }
        
        // Unlock "First Test" if a successful test flag is set in UserDefaults
        if UserDefaults.standard.bool(forKey: "lastTestSuccessful") {
            unlockAchievement(named: "First Test")
        }
        
        // Unlock "Upload 5 Images" if at least 5 images are stored
        let knowledge = StorageManager.shared.loadImages()
        let numberOfImages = knowledge.values.reduce(0) { $0 + $1.count }
        if numberOfImages >= 5 {
            unlockAchievement(named: "Upload 5 Images")
        }
        
        // Unlock "Complete Knowledge" if total points are at least 500
        if DailyChallengeManager.shared.totalPoints >= 500 {
            unlockAchievement(named: "Complete Knowledge")
        }
    }
}
