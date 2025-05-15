import UIKit

// Manages saving, loading, and deleting images and their metadata
class StorageManager {
    static let shared = StorageManager() // Singleton instance
    private let defaults = UserDefaults.standard // UserDefaults for metadata storage

    // Returns the URL of the folder where images are stored
    private func getImgFolderURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("img")
    }

    // Saves an image to the file system and associates it with a label
    func saveImage(_ image: UIImage, label: String) -> String? {
        let imageName = UUID().uuidString + ".png"
        let imgFolderURL = getImgFolderURL()

        if !FileManager.default.fileExists(atPath: imgFolderURL.path) {
            try? FileManager.default.createDirectory(at: imgFolderURL, withIntermediateDirectories: true, attributes: nil)
        }

        if let imageData = image.pngData() {
            let imageURL = imgFolderURL.appendingPathComponent(imageName)
            try? imageData.write(to: imageURL)

            var metadata = defaults.dictionary(forKey: "imageMetadata") as? [String: String] ?? [:]
            metadata[imageName] = label
            defaults.setValue(metadata, forKey: "imageMetadata")

            return imageName
        }
        return nil
    }

    // Loads all saved images and organizes them by their labels
    func loadImages() -> [String: [UIImage]] {
        var result: [String: [UIImage]] = [:]
        let imgFolderURL = getImgFolderURL()
        let metadata = defaults.dictionary(forKey: "imageMetadata") as? [String: String] ?? [:]

        for (imageName, label) in metadata {
            let imageURL = imgFolderURL.appendingPathComponent(imageName)
            if let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) {
                if result[label] == nil {
                    result[label] = []
                }
                result[label]?.append(image)
            }
        }
        return result
    }

    // Deletes an image from the file system and removes its metadata
    func deleteImage(_ imageName: String) {
        let imgFolderURL = getImgFolderURL()
        let imageURL = imgFolderURL.appendingPathComponent(imageName)

        try? FileManager.default.removeItem(at: imageURL)

        var metadata = defaults.dictionary(forKey: "imageMetadata") as? [String: String] ?? [:]
        metadata.removeValue(forKey: imageName)
        defaults.setValue(metadata, forKey: "imageMetadata")
    }
}
