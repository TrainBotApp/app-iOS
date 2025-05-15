import SwiftUI

// Displays a congratulatory popup when an achievement is unlocked
struct AchievementUnlockView: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    let achievement: Achievement // The unlocked achievement to display
    @Binding var isPresented: Bool // Controls whether the view is visible
    
    var body: some View {
        VStack(spacing: 15) {
            // Star icon to indicate achievement unlock
            Image(systemName: "star.fill")
                .font(.system(size: 50)) // Large star icon
                .foregroundColor(.yellow) // Yellow color for emphasis
            
            Text("Achievement Unlocked!")
                .font(.headline) // Title text
            
            Text(achievement.name)
                .font(.title3) // Display the name of the unlocked achievement
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.subheadline) // Display the description of the achievement
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Button to dismiss the popup
            Button("OK") {
                isPresented = false // Hide the view when the button is tapped
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue) // Blue background for the button
            .foregroundColor(.white) // White text for the button
            .clipShape(Capsule()) // Rounded button shape
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray5) : .white) // Adjust background for dark mode
                .shadow(radius: 10) // Add shadow for a popup effect
        )
        .padding(.horizontal, 40) // Add horizontal padding
        .transition(.scale.combined(with: .opacity)) // Add scale and opacity transition
    }
}
