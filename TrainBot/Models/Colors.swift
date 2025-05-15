import SwiftUI

// Extends the Color struct to define custom colors used throughout the app
extension Color {
    static let primaryBlue = Color("PrimaryBlue") // Custom blue color for primary UI elements
    static let primaryGreen = Color("PrimaryGreen") // Custom green color for success or positive actions
    static let primaryOrange = Color("PrimaryOrange") // Custom orange color for warnings or highlights
    static let backgroundLight = Color(UIColor.systemBackground) // Light mode background color
    static let backgroundDark = Color(UIColor.systemBackground) // Dark mode background color (same as system background)
    
    // Returns the appropriate background color based on the current color scheme
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }
}
