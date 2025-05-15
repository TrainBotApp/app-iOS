import SwiftUI
import PhotosUI
import CoreML
import Vision
import AudioToolbox

// Displays the testing screen where users can test the bot's predictions
struct TestingView: View {
    @Binding var knowledgeData: [String: [UIImage]] // Knowledge base data
    @State private var selectedImage: PhotosPickerItem? = nil // Selected image from the photo picker
    @State private var testImage: UIImage? = nil // Image to be tested
    @State private var testResult: String? = nil // Result of the test
    @State private var isProcessing = false // Indicates whether the test is in progress
    @State private var imageSize: CGSize? = nil // Size of the test image
    @EnvironmentObject var settings: AppSettings // Access shared app settings
    @Environment(\.colorScheme) var colorScheme // Access the current color scheme
    private let scaleFactor: CGFloat = 0.3 // Scale factor for resizing images
    
    var body: some View {
        GeometryReader { geometry in
            let maxImageWidth = geometry.size.width * 0.8 // Maximum width for the test image
            let displaySize: CGSize = {
                if let size = imageSize, size.height > 0 {
                    let aspectRatio = size.width / size.height
                    return CGSize(width: maxImageWidth, height: maxImageWidth / aspectRatio)
                }
                // Fallback: use 80% of screen width and 40% of screen height for placeholder
                return CGSize(width: maxImageWidth, height: geometry.size.height * 0.4)
            }()
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.green.opacity(0.10), .blue.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView { // Wrap main content in ScrollView
                    VStack(spacing: 25) {
                        // Description of Test ML functionality
                        Text("Test \(settings.botName)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                            .padding(.top, 30)
                        // Description of Train ML functionality
                        Text("Test your machine learning model's performance.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                        
                        // Placeholder or test image display
                        ZStack {
                            if let testImage = testImage {
                                Image(uiImage: testImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: displaySize.width, height: displaySize.height)
                                    .blur(radius: isProcessing ? 6 : 0)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: displaySize.width, height: displaySize.height)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(radius: 10)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(width: displaySize.width, height: displaySize.height)
                                    .blur(radius: isProcessing ? 6 : 0)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: displaySize.width, height: displaySize.height)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(radius: 10)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 50))
                                            .foregroundColor(Color(UIColor.tertiaryLabel))
                                    )
                            }
                            
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(width: displaySize.width, height: displaySize.height)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                        .animation(.spring(), value: testImage)
                        
                        // Photo picker for selecting an image
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Select Image")
                            }
                            .font(.headline)
                            .foregroundColor(Color(UIColor.white))
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [.systemBlue, .systemPurple].map { Color($0) },
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal, 30)
                        
                        // Display the test result
                        if let testResult = testResult {
                            Text(testResult)
                                .font(.headline)
                                .foregroundColor(Color(UIColor.label))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .shadow(radius: 5)
                                )
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 30)
                        
                        // Button to start the test
                        Button {
                            Task {
                                await evaluateImage()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Test Image")
                            }
                            .font(.headline)
                            .foregroundColor(Color(UIColor.white))
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [.systemGreen, .systemBlue].map { Color($0) },
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                        .disabled(testImage == nil || isProcessing) // Disable button if no image is selected or processing
                    }
                    .padding()
                } // End ScrollView
            }
            .onChange(of: selectedImage) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        testImage = uiImage
                        imageSize = uiImage.size
                        testResult = nil
                    }
                }
            }
        }
    }
    
    // Evaluates the selected image and generates a prediction
    private func evaluateImage() async {
        guard let image = testImage else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        guard let testFeatures = await ImageClassifier.shared.extractAdvancedFeatures(from: image) else {
            await MainActor.run {
                testResult = "Error: Unable to process image"
            }
            return
        }
        
        print("Extracted features count: \(testFeatures.count)")
        
        var bestMatches: [(label: String, confidence: Double)] = []
        
        for (label, images) in knowledgeData {
            for trainedImage in images {
                if let trainedFeatures = await ImageClassifier.shared.extractAdvancedFeatures(from: trainedImage) {
                    let minCount = min(testFeatures.count, trainedFeatures.count)
                    let similarity = ImageClassifier.shared.cosineSimilarity(
                        Array(testFeatures.prefix(minCount)),
                        Array(trainedFeatures.prefix(minCount))
                    )
                    bestMatches.append((label: label, confidence: similarity))
                }
            }
        }
        
        bestMatches.sort { $0.confidence > $1.confidence }
        
        // Play a system sound when testing is performed
        AudioServicesPlaySystemSound(1104) // Tock sound
        
        if let bestMatch = bestMatches.first {
            let confidence = Int(bestMatch.confidence * 100)
            await MainActor.run {
                testResult = "\(bestMatch.label) (\(confidence)% confident)"
                if !testResult!.contains("Error") {
                    settings.achievementsManager.unlockAchievement(named: "First Test")
                }
            }
        } else {
            await MainActor.run {
                testResult = "No matches found"
            }
        }
    }
}
