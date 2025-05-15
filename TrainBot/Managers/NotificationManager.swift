import UserNotifications
import Foundation

// Manages scheduling and sending notifications for the app
class NotificationManager {
    static let shared = NotificationManager() // Singleton instance for shared access
    
    private init() {} // Private initializer to enforce singleton pattern
    
    // Requests notification authorization from the user
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error.localizedDescription)")
            } else {
                print("Notification auth granted: \(granted)")
            }
        }
    }
    
    // Schedules daily reminders for the user to train their bot
    func scheduleReminders(for mlName: String) {
        // Cancel any existing notifications to avoid duplicates
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Define playful notification messages for different times of the day
        let playfulMessages: [String: [(title: String, body: String)]] = [
            "Morning": [
                (title: "Rise & Shine, \(mlName) Trainer!", body: "Good morning! Your \(mlName) needs a little sparkle. Time to train!"),
                (title: "Wake Up Call!", body: "Morning vibes: boost your \(mlName) with some fun training!")
            ],
            "Afternoon": [
                (title: "Afternoon Adventure!", body: "Hey, it's snack time & training time for your \(mlName)! Keep it rolling!"),
                (title: "Keep Moving!", body: "Afternoon energy boost: train your \(mlName) and show it who's boss!")
            ],
            "Evening": [
                (title: "Dream Big Tonight", body: "Evening chill: train your \(mlName) before you unwind and dream."),
                (title: "Night Owl Alert!", body: "The night calls for a quick \(mlName) training session. Let's do it!")
            ]
        ]
        
        // Define the times for morning, afternoon, and evening notifications
        let times = [
            ("Morning", 9, 0),    // 9:00 AM
            ("Afternoon", 13, 0), // 1:00 PM
            ("Evening", 19, 0)    // 7:00 PM
        ]
        
        // Schedule notifications for each time period
        for (period, hour, minute) in times {
            let options = playfulMessages[period] ?? []
            let chosen = options.randomElement() ?? (title: "Time to Train \(mlName)", body: "Don't forget to train your \(mlName)!")
            
            let content = UNMutableNotificationContent()
            content.title = chosen.title // Notification title
            content.body = chosen.body // Notification body
            content.sound = .default // Default notification sound
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            // Set the trigger to repeat daily at the specified time
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(mlName)-\(period)" // Unique identifier for the notification
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Add the notification request to the notification center
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification (\(identifier)): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Sends a congratulation notification for unlocking an achievement
    func sendCongratulationNotification(for achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!" // Notification title
        content.body = "You've unlocked the achievement: \(achievement.name)" // Notification body
        content.sound = .default // Default notification sound
        
        // Trigger the notification immediately
        let request = UNNotificationRequest(identifier: "achievement-\(achievement.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
