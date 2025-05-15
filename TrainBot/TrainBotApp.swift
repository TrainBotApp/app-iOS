//
//  TrainBotApp.swift
//  TrainBot
//
//  Created by Luca Moldovan on 05.05.2025.
//

import SwiftUI

@main
struct TrainBotApp: App {
    @StateObject private var settings = AppSettings() // Shared app settings
    
    init() {
        // Request notification authorization when app launches
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            // Check if the bot setup is completed; show onboarding if not
            if UserDefaults.standard.bool(forKey: "isBotSetupCompleted") {
                OnboardingView()
                    .environmentObject(settings)
            } else {
                BotSetupView()
                    .environmentObject(settings)
            }
        }
    }
}
