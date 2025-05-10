//
//  ContentView.swift
//  Pet Image Classifier
//
//  Created by Rohan Katyayani on 09/05/25.
//

import SwiftUI
import CoreML
import Vision

struct ContentView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil
    @State private var classificationLabel: String = "Tap the button to take a picture"

    var body: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(Text("No Image Captured"))
            }

            Text(classificationLabel)
                .font(.title2)
                .padding()

            Button(action: {
                showCamera = true
            }) {
                Text("Take a Picture")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showCamera) {
                CameraImagePicker(image: $capturedImage)
                    .onDisappear {
                        if let image = capturedImage {
                            classifyImage(image)
                        }
                    }
            }
        }
        .padding()
    }

    func classifyImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            classificationLabel = "Unable to convert image"
            return
        }

        guard let model = try? VNCoreMLModel(for: MyImageClassifier().model) else {
            classificationLabel = "Failed to load ML model"
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                DispatchQueue.main.async {
                    classificationLabel = "\(topResult.identifier.capitalized) (\(String(format: "%.2f", topResult.confidence * 100))%)"
                }
            } else {
                DispatchQueue.main.async {
                    classificationLabel = "Could not classify image"
                }
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
    }
}
