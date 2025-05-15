import Foundation

// Represents an image entry in the app's knowledge base
struct ImageEntry: Identifiable {
    let id = UUID().uuidString // Unique identifier for the image entry
    var label: String = "" // Label associated with the image (e.g., "Cat")
    var imageName: String = "" // Name of the image file stored in the file system
}
