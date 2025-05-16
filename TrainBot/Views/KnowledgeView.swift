import SwiftUI

// Displays the knowledge base, allowing users to view and manage labeled images
struct KnowledgeView: View {
    @Binding var knowledgeData: [String: [UIImage]] // Dictionary of labels and their associated images
    @EnvironmentObject var settings: AppSettings // Access shared app settings
    @State private var showingDeleteAlert = false // Tracks whether the delete confirmation alert is shown
    @State private var labelToDelete: String? = nil // Stores the label to be deleted
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.orange.opacity(0.12), .blue.opacity(0.10)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header for the knowledge base
                Text("Knowledge Base")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    .padding(.top, 30)
            
                // Description of the knowledge base
                Text("Discover and organize your collected images to train your bot.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Display an empty state if no knowledge data exists
                if knowledgeData.isEmpty {
                    EmptyStateView()
                } else {
                    // Display a grid of knowledge cards
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                  spacing: 20) {
                            ForEach(knowledgeData.keys.sorted(), id: \.self) { key in
                                KnowledgeCard(
                                    label: key,
                                    images: knowledgeData[key] ?? [],
                                    onDeleteImage: { image in
                                        deleteImage(image, label: key)
                                    },
                                    onDeleteLabel: {
                                        labelToDelete = key
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .alert("Delete Label", isPresented: $showingDeleteAlert, presenting: labelToDelete) { label in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteLabel(label)
            }
        } message: { label in
            Text("Are you sure you want to delete '\(label)' and all its images?")
        }
        .onAppear {
            loadKnowledgeData() // Load knowledge data when the view appears
        }
    }
    
    // Loads knowledge data from the storage manager
    private func loadKnowledgeData() {
        knowledgeData = StorageManager.shared.loadImages()
    }
    
    // Deletes a specific image from the knowledge base
    private func deleteImage(_ image: UIImage, label: String) {
        let metadata = UserDefaults.standard.dictionary(forKey: "imageMetadata") as? [String: String] ?? [:]
        if let imageName = metadata.first(where: { $0.value == label })?.key {
            StorageManager.shared.deleteImage(imageName)
            
            if let index = knowledgeData[label]?.firstIndex(of: image) {
                knowledgeData[label]?.remove(at: index)
            }
        }
    }
    
    // Deletes an entire label and its associated images
    private func deleteLabel(_ label: String) {
        // Delete all images for this label
        let metadata = UserDefaults.standard.dictionary(forKey: "imageMetadata") as? [String: String] ?? [:]
        metadata.forEach { imageName, imageLabel in
            if imageLabel == label {
                StorageManager.shared.deleteImage(imageName)
            }
        }
        
        // Remove label from knowledgeData
        knowledgeData.removeValue(forKey: label)
    }
}

// A reusable card view for displaying a label and its associated images
struct KnowledgeCard: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    let label: String // The label for the knowledge card
    let images: [UIImage] // Images associated with the label
    let onDeleteImage: (UIImage) -> Void // Callback for deleting an image
    let onDeleteLabel: () -> Void // Callback for deleting the label
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Button(action: onDeleteLabel) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding([.top, .horizontal])
            
            // Horizontal scroll view for displaying images
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(
                                Button(action: { onDeleteImage(image) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                .offset(x: 30, y: -30),
                                alignment: .topTrailing
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(colorScheme == .dark ? .systemGray5 : .white))
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// A view displayed when the knowledge base is empty
struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Knowledge Data")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Start training your bot to build its knowledge base")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .foregroundColor(Color(.systemGray))
    }
}
