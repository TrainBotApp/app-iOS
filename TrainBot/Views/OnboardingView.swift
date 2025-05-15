import SwiftUI

// Displays the onboarding screen with navigation to key app features
struct OnboardingView: View {
    @EnvironmentObject var settings: AppSettings // Access shared app settings
    @State private var knowledgeData: [String: [UIImage]] = [:] // Knowledge base data
    @State private var selectedTab = 0 // Tracks the selected tab
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.10), .purple.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Welcome message with the bot's name
                    Text("Welcome to \(settings.botName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                        .padding(.top, 30)
                    
                    // Main actions grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        // Training card
                        NavigationLink {
                            TrainingView()
                                .environmentObject(settings)
                        } label: {
                            ActionCard(
                                title: "Train",
                                subtitle: "Teach your bot",
                                icon: "graduationcap.fill",
                                color: .blue
                            )
                        }
                        
                        // Testing card
                        NavigationLink {
                            TestingView(knowledgeData: $knowledgeData)
                                .environmentObject(settings)
                        } label: {
                            ActionCard(
                                title: "Test",
                                subtitle: "Try your bot",
                                icon: "magnifyingglass",
                                color: .green
                            )
                        }
                        
                        // Knowledge card
                        NavigationLink {
                            KnowledgeView(knowledgeData: $knowledgeData)
                                .environmentObject(settings)
                        } label: {
                            ActionCard(
                                title: "Knowledge",
                                subtitle: "View database",
                                icon: "brain.head.profile",
                                color: .orange
                            )
                        }
                        
                        // Daily challenge card
                        NavigationLink {
                            DailyChallengeView()
                                .environmentObject(settings)
                        } label: {
                            ActionCard(
                                title: "Daily",
                                subtitle: "Take challenge",
                                icon: "star.fill",
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Achievements button
                    NavigationLink {
                        AchievementsView()
                            .environmentObject(settings)
                    } label: {
                        HStack {
                            Image(systemName: "trophy.fill")
                            Text("Achievements")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                
                // Achievement unlock overlay
                if settings.achievementsManager.showingUnlockAlert,
                   let achievement = settings.achievementsManager.lastUnlockedAchievement {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    AchievementUnlockView(
                        achievement: achievement,
                        isPresented: $settings.achievementsManager.showingUnlockAlert
                    )
                }
            }
            .navigationBarItems(leading: settingsButton)
            .navigationBarBackButtonHidden(true)
        }
        .environmentObject(settings)
    }
    
    // Settings button in the navigation bar
    private var settingsButton: some View {
        NavigationLink {
            SettingsView()
                .environmentObject(settings)
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.primary)
                .imageScale(.large)
        }
    }
}

// A reusable card view for displaying main actions
struct ActionCard: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    let title: String // Title of the action
    let subtitle: String // Subtitle of the action
    let icon: String // Icon for the action
    let color: Color // Color for the icon
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppSettings())
    }
}
