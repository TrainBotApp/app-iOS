import SwiftUI

// Displays the settings screen where users can customize app preferences
struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings // Access shared app settings
    @Environment(\.colorScheme) var colorScheme: ColorScheme // Access the current color scheme
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.10), .green.opacity(0.10)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header for the settings screen
                Text("Settings")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.top, 30)
                
                // Card for updating the bot's name
                SettingsCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Bot Name")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter Bot Name", text: $settings.botName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Card for toggling sound effects
                SettingsCard {
                    Toggle("Sound Effects", isOn: .constant(true)) // Placeholder toggle
                        .padding()
                }
                
                Spacer() // Push content to the top
            }
            .padding()
        }
    }
}

// A reusable card view for displaying settings options
struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme // Access the current color scheme
    let content: Content // Content to display inside the card
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(colorScheme == .dark ? .systemGray5 : .systemBackground)) // Adjust background for dark mode
                    .shadow(radius: 5) // Add shadow for a card effect
            )
            .padding(.horizontal)
    }
}