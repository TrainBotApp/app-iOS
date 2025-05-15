import Foundation

// Represents a daily challenge in the app
public struct DailyChallenge: Identifiable {
    public let id = UUID() // Unique identifier for the challenge
    public let title: String // Title of the challenge (e.g., "Train Your Bot")
    public let description: String // Description of the challenge
    public let category: ChallengeCategory // Category of the challenge (e.g., training, testing)
    public let difficulty: ChallengeDifficulty // Difficulty level of the challenge
    public let targetCount: Int // Target count to complete the challenge (e.g., number of images)

    // Enum for challenge categories
    public enum ChallengeCategory: String, CaseIterable {
        case training = "Training" // Challenges related to training the bot
        case testing = "Testing" // Challenges related to testing the bot
        case organization = "Organization" // Challenges related to organizing data
        case exploration = "Exploration" // Challenges related to exploring new content
    }
    
    // Enum for challenge difficulty levels
    public enum ChallengeDifficulty: String, CaseIterable {
        case easy = "Easy" // Easy difficulty level
        case medium = "Medium" // Medium difficulty level
        case hard = "Hard" // Hard difficulty level
        
        // Points awarded for completing a challenge based on its difficulty
        public var points: Int {
            switch self {
            case .easy: return 10
            case .medium: return 20
            case .hard: return 30
            }
        }
    }
    
    // Initializes a new daily challenge
    public init(title: String, description: String, category: ChallengeCategory, difficulty: ChallengeDifficulty) {
        self.title = title // Set the title of the challenge
        self.description = description // Set the description of the challenge
        self.category = category // Set the category of the challenge
        self.difficulty = difficulty // Set the difficulty level of the challenge
        self.targetCount = difficulty == .hard ? 10 : (difficulty == .medium ? 7 : 5) // Set the target count based on difficulty
    }
}
