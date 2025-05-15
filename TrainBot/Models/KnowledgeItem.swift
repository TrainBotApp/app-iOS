import Foundation

// Represents an item in the app's knowledge base
struct KnowledgeItem: Identifiable, Codable {
    let id: UUID // Unique identifier for the knowledge item
    let title: String // Title of the knowledge item (e.g., "Cat")
    let content: String // Content or description of the knowledge item

    // Initializes a new knowledge item with a unique ID, title, and content
    init(id: UUID = UUID(), title: String, content: String) {
        self.id = id // Assign a unique identifier
        self.title = title // Set the title of the knowledge item
        self.content = content // Set the content or description
    }
}
