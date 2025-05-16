import SwiftUI

// Displays the daily challenge and tracks progress
struct DailyChallengeView: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    @State private var challenge: DailyChallenge // The current daily challenge
    @State private var isCompleted = false // Indicates whether the challenge is completed
    @State private var todayChallenge: DailyChallenge = DailyChallengeManager.shared.getTodayChallenge() // Fetch today's challenge
    @ObservedObject private var dailyManager = DailyChallengeManager.shared // Access the shared daily challenge manager
    
    init() {
        _challenge = State(initialValue: DailyChallengeManager.shared.getTodayChallenge()) // Initialize the challenge state
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.15), .blue.opacity(0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
                        
            VStack(spacing: 25) {
                // Title for the daily challenge view
                Text("Daily Challenge")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .padding(.top, 30)
                
                // Challenge card displaying details of the current challenge
                VStack(spacing: 20) {
                    // Icon representing the challenge category
                    Image(systemName: challenge.category == .training ? "graduationcap.fill" : "speedometer")
                        .font(.system(size: 50))
                        .foregroundColor(challenge.category == .training ? .blue : .green)
                    
                    // Challenge title
                    Text(challenge.title)
                        .font(.title2)
                        .bold()
                    
                    // Challenge description
                    Text(challenge.description)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    // Badge for the challenge difficulty
                    Text(challenge.difficulty.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(difficultyColor(challenge.difficulty))
                        )
                        .foregroundColor(.white)
                    
                    // Progress bar for tracking challenge completion
                    ProgressView(value: Double(dailyManager.progress), total: 5.0)
                        .padding(.horizontal)
                    
                    // Text showing the current progress
                    Text("\(dailyManager.progress)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(.systemGray5) : .white) // Adjust background for dark mode
                        .shadow(radius: 5)
                )
                .padding(.horizontal)
                
                // Reward preview displayed upon challenge completion
                if isCompleted {
                    Text("🎉 +\(difficultyPoints(challenge.difficulty)) Points!")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Display total points earned
                Text("Total Points: \(dailyManager.totalPoints)")
                    .font(.body)
                    .padding(.top)
            }
            .padding()
        }
    }
    
    // Returns the color associated with the challenge difficulty
    private func difficultyColor(_ difficulty: DailyChallenge.ChallengeDifficulty) -> Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
    
    // Returns the points awarded for completing a challenge based on its difficulty
    private func difficultyPoints(_ difficulty: DailyChallenge.ChallengeDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return 10
        case .medium:
            return 20
        case .hard:
            return 30
        }
    }
}

struct DailyChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        DailyChallengeView()
    }
}
