import SwiftUI

// Displays a list of achievements and their statuses
struct AchievementsView: View {
    @EnvironmentObject var settings: AppSettings // Access shared app settings
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Format dates as short strings
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.10), .blue.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    // Iterate through all achievements and display them
                    ForEach(settings.achievementsManager.achievements) { achievement in
                        HStack {
                            // Display an icon based on whether the achievement is unlocked
                            if achievement.unlocked {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green) // Green for unlocked achievements
                            } else {
                                Image(systemName: "seal")
                                    .foregroundColor(.gray) // Gray for locked achievements
                            }
                            VStack(alignment: .leading) {
                                Text(achievement.name)
                                    .font(achievement.unlocked ? .headline : .body) // Highlight unlocked achievements
                                Text(achievement.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary) // Secondary color for descriptions
                                if let date = achievement.unlockedDate, achievement.unlocked {
                                    Text("Unlocked: \(date, formatter: dateFormatter)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary) // Show unlock date for unlocked achievements
                                }
                            }
                        }
                        .padding(.vertical, 4) // Add vertical padding between items
                    }
                }
                .navigationTitle("Achievements") // Set the navigation title
            }
        }
        .onAppear {
            AchievementsManager.shared.updateAchievementsAfterChallenge()
        }
    }
}

// A reusable card view for displaying individual achievements
struct AchievementCard: View {
    let achievement: Achievement // The achievement to display
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme

    var body: some View {
        HStack(spacing: 15) {
            // Circular icon indicating the achievement's status
            Circle()
                .fill(achievement.unlocked ? Color.green : Color.gray) // Green for unlocked, gray for locked
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "star.fill")
                        .foregroundColor(.white) // White star icon
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.name)
                    .font(.headline) // Display the achievement name
                
                Text(achievement.unlocked ? "Completed" : "Locked")
                    .font(.subheadline)
                    .foregroundColor(.gray) // Display the status of the achievement
            }
            
            Spacer() // Push content to the left
            
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green) // Green checkmark for unlocked achievements
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white)) // Adjust background for dark mode
                .shadow(radius: 5) // Add shadow for a card effect
        )
    }
}
