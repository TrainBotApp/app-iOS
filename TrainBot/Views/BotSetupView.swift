import SwiftUI

// Displays the initial setup screen for configuring the bot
struct BotSetupView: View {
    @EnvironmentObject var settings: AppSettings // Access shared app settings
    @Environment(\.dismiss) var dismiss // Dismiss the view when setup is complete
    @State private var name: String = "" // Stores the user-inputted bot name
    
    var body: some View {
        VStack(spacing: 20) {
            // Welcome message
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Description of the app
            Text("TrainBot is an innovative app that challenges you every day with engaging tasks to enhance your Machine Learning skills. Prepare to learn, train, and grow with every challenge!")
                .multilineTextAlignment(.center)
                .padding()
            
            // Section title for bot setup
            Text("Set Up Your Bot")
                .font(.title)
            
            // Text field for entering the bot name
            TextField("Enter bot name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Save button to complete the setup
            Button("Save") {
                settings.botName = name.isEmpty ? "TrainBot" : name // Use default name if none is provided
                UserDefaults.standard.set(true, forKey: "isBotSetupCompleted") // Mark setup as complete
                dismiss() // Dismiss the setup view
            }
            .padding()
        }
        .padding()
    }
}

struct BotSetupView_Previews: PreviewProvider {
    static var previews: some View {
        BotSetupView()
    }
}
