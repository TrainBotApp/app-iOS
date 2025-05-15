import CoreML
import Vision
import UIKit
import Accelerate

class ImageClassifier {
    static let shared = ImageClassifier()
    private var classificationRequest: VNCoreMLRequest?
    private var model: MLModel?
    private var trainingData: [String: [(features: [Double], image: UIImage)]] = [:]
    private let modelName = "MobileNetV2"
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            config.allowLowPrecisionAccumulationOnGPU = true
            config.computeUnits = .all
            
            // Try to load model from the bundle
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                model = try MLModel(contentsOf: modelURL, configuration: config)
                
                if let visionModel = try? VNCoreMLModel(for: model!) {
                    let request = VNCoreMLRequest(model: visionModel) { request, error in
                        if let error = error {
                            print("Vision request error: \(error.localizedDescription)")
                            return
                        }
                    }
                    request.imageCropAndScaleOption = .centerCrop
                    classificationRequest = request
                }
            } else {
                // Try to download and compile model if not in bundle
                Task {
                    await downloadAndCompileModel()
                }
            }
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
            classificationRequest = nil
        }
    }
    
    private func downloadAndCompileModel() async {
        // URL for the MobileNetV2 model
        let modelURL = URL(string: "https://ml-assets.apple.com/coreml/models/MobileNetV2.mlmodel")!
        
        do {
            let (_, _) = try await URLSession.shared.data(from: modelURL)
            let compiledModelURL = try await MLModel.compileModel(at: modelURL)
            model = try MLModel(contentsOf: compiledModelURL)
            
            if let visionModel = try? VNCoreMLModel(for: model!) {
                let request = VNCoreMLRequest(model: visionModel)
                request.imageCropAndScaleOption = .centerCrop
                classificationRequest = request
            }
        } catch {
            print("Failed to download/compile model: \(error.localizedDescription)")
        }
    }
    
    func classify(_ image: UIImage) async -> String {
        guard let cgImage = image.cgImage else {
            return "Error: Unable to process image"
        }
        
        // Try ML classification first
        if let request = classificationRequest {
            do {
                let handler = VNImageRequestHandler(cgImage: cgImage)
                try handler.perform([request])
                
                if let observations = request.results as? [VNClassificationObservation],
                   let topResult = observations.first {
                    let confidence = Int(topResult.confidence * 100)
                    return "\(topResult.identifier) (\(confidence)% confident)"
                }
            } catch {
                print("ML classification failed: \(error.localizedDescription)")
                // Fall through to advanced feature extraction
            }
        }
        
        // Fallback to advanced feature extraction
        if let features = await extractAdvancedFeatures(from: image) {
            let (classification, confidence) = classifyWithAdvancedFeatures(features)
            return "\(classification) (\(confidence)% confident)"
        }
        
        return "Unable to analyze image"
    }
    
    // Advanced feature extraction combining color, edges, and texture
    func extractAdvancedFeatures(from image: UIImage) async -> [Double]? {
        guard let cgImage = image.cgImage else { return nil }
        
        var features: [Double] = []
        
        // 1. Color features (histogram)
        let colorFeatures = extractColorHistogram(from: cgImage)
        features.append(contentsOf: colorFeatures)
        
        // 2. Edge features
        let edgeFeatures = extractEdgeFeatures(from: cgImage)
        features.append(contentsOf: edgeFeatures)
        
        // 3. Texture features (using Local Binary Patterns)
        let textureFeatures = extractTextureFeatures(from: cgImage)
        features.append(contentsOf: textureFeatures)
        
        return features.isEmpty ? nil : features
    }
    
    private func extractColorHistogram(from cgImage: CGImage) -> [Double] {
        var histogram = Array(repeating: 0.0, count: 768) // 256 bins for each RGB channel
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let context = CGContext(data: &rawBytes,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: bytesPerRow,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        for i in stride(from: 0, to: rawBytes.count, by: bytesPerPixel) {
            histogram[Int(rawBytes[i])] += 1     // R
            histogram[Int(rawBytes[i + 1]) + 256] += 1 // G
            histogram[Int(rawBytes[i + 2]) + 512] += 1 // B
        }
        
        // Normalize histogram
        let pixelCount = Double(width * height)
        return histogram.map { $0 / pixelCount }
    }
    
    private func extractEdgeFeatures(from cgImage: CGImage) -> [Double] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let context = CGContext(data: &rawBytes,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: bytesPerRow,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var edgeFeatures: [Double] = []
        let sobelX: [Float] = [-1, 0, 1, -2, 0, 2, -1, 0, 1]
        let sobelY: [Float] = [-1, -2, -1, 0, 0, 0, 1, 2, 1]
        
        // Convert to grayscale and apply Sobel operators
        for y in 1..<height-1 {
            for x in 1..<width-1 {
                var gx: Float = 0
                var gy: Float = 0
                
                for ky in -1...1 {
                    for kx in -1...1 {
                        let pos = ((y + ky) * width + (x + kx)) * bytesPerPixel
                        let pixel = Float(rawBytes[pos])
                        let k = (ky + 1) * 3 + (kx + 1)
                        gx += pixel * sobelX[k]
                        gy += pixel * sobelY[k]
                    }
                }
                
                let magnitude = sqrt(gx * gx + gy * gy)
                edgeFeatures.append(Double(magnitude))
            }
        }
        
        // Reduce edge features to a fixed-size histogram
        let bins = 32
        var edgeHistogram = Array(repeating: 0.0, count: bins)
        let maxMagnitude = edgeFeatures.max() ?? 1.0
        
        for magnitude in edgeFeatures {
            let bin = Int((magnitude / maxMagnitude) * Double(bins - 1))
            edgeHistogram[bin] += 1
        }
        
        // Normalize histogram
        let total = edgeHistogram.reduce(0, +)
        return edgeHistogram.map { $0 / total }
    }
    
    private func extractTextureFeatures(from cgImage: CGImage) -> [Double] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let context = CGContext(data: &rawBytes,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: bytesPerRow,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Simple LBP implementation
        var lbpHistogram = Array(repeating: 0.0, count: 256)
        
        for y in 1..<height-1 {
            for x in 1..<width-1 {
                var lbpValue: UInt8 = 0
                let centerPixel = rawBytes[(y * width + x) * bytesPerPixel]
                
                // Compare with 8 neighbors
                let neighbors = [
                    (-1,-1), (-1,0), (-1,1),
                    (0,-1),          (0,1),
                    (1,-1),  (1,0),  (1,1)
                ]
                
                for (i, (dy, dx)) in neighbors.enumerated() {
                    let neighbor = rawBytes[((y + dy) * width + (x + dx)) * bytesPerPixel]
                    if neighbor > centerPixel {
                        lbpValue |= 1 << i
                    }
                }
                
                lbpHistogram[Int(lbpValue)] += 1
            }
        }
        
        // Normalize histogram
        let total = lbpHistogram.reduce(0, +)
        return lbpHistogram.map { $0 / total }
    }
    
    private func classifyWithAdvancedFeatures(_ features: [Double]) -> (String, Int) {
        // Analyze feature vectors to determine image characteristics
        let colorFeatures = Array(features.prefix(768))
        let edgeFeatures = Array(features[768..<(768 + 32)])
        let textureFeatures = Array(features.suffix(256))
        
        // Color analysis
        let avgBrightness = colorFeatures.reduce(0, +) / Double(colorFeatures.count)
        let colorVariance = colorFeatures.map { pow($0 - avgBrightness, 2) }.reduce(0, +) / Double(colorFeatures.count)
        
        // Edge analysis
        let edgeIntensity = edgeFeatures.reduce(0, +) / Double(edgeFeatures.count)
        
        // Texture analysis
        let textureComplexity = textureFeatures.filter { $0 > 0.01 }.count
        
        // Classification logic
        if edgeIntensity > 0.5 && textureComplexity > 100 {
            return ("Complex Textured", 85)
        } else if edgeIntensity > 0.3 {
            return ("Edge-Rich", 80)
        } else if colorVariance > 0.1 {
            return ("Color-Diverse", 75)
        } else if avgBrightness > 0.7 {
            return ("Bright Scene", 70)
        } else if avgBrightness < 0.3 {
            return ("Dark Scene", 70)
        }
        
        return ("Neutral Scene", 65)
    }

    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count && !a.isEmpty else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard normA > 0 && normB > 0 else { return 0 }
        return dotProduct / (normA * normB)
    }

    func updateModel(with images: [UIImage], label: String) async {
        if trainingData[label] == nil {
            trainingData[label] = []
        }
        
        for image in images {
            if let features = await extractAdvancedFeatures(from: image) {
                trainingData[label]?.append((features: features, image: image))
                print("Stored features for \(label)")
            }
        }
    }

    func predictFromKnowledge(_ image: UIImage, knowledgeData: [String: [UIImage]]) async -> (label: String, confidence: Double)? {
        guard let testFeatures = await extractCoreMLFeatures(from: image) else { return nil }
        var bestMatch: (label: String, confidence: Double)?
        for (label, images) in knowledgeData {
            let recentImages = images.suffix(5)
            for trainedImage in recentImages {
                if let trainedFeatures = await extractCoreMLFeatures(from: trainedImage) {
                    let minCount = min(testFeatures.count, trainedFeatures.count)
                    let similarity = cosineSimilarity(
                        Array(testFeatures.prefix(minCount)),
                        Array(trainedFeatures.prefix(minCount))
                    )
                    if let current = bestMatch {
                        if similarity > current.confidence {
                            bestMatch = (label: label, confidence: similarity)
                        }
                    } else {
                        bestMatch = (label: label, confidence: similarity)
                    }
                }
            }
        }
        return bestMatch
    }

    // Downscale image to 224x224 for faster processing
    private func downscale(image: UIImage, to size: CGSize = CGSize(width: 224, height: 224)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }

    // Extract features using CoreML MobileNetV2
    func extractCoreMLFeatures(from image: UIImage) async -> [Double]? {
        guard let model = self.model else { return nil }
        guard let downscaled = downscale(image: image),
              let buffer = downscaled.pixelBuffer(width: 224, height: 224) else { return nil }
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: ["image": buffer])
            let outFeatures = try await model.prediction(from: input)
            if let features = outFeatures.featureValue(for: "feature_vector")?.multiArrayValue {
                // MLMultiArray does not have 'map', so convert manually
                return (0..<features.count).map { Double(truncating: features[$0]) }
            }
        } catch {
            print("CoreML feature extraction failed: \(error)")
        }
        return nil
    }
}

// Extension for UIImage to CVPixelBuffer
extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
