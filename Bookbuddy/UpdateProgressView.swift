//
//  UpdateProgressView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
import Speech
internal import CoreData

struct UpdateProgressView: View {
    let book: Book
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var speechManager = SpeechRecognitionManager()
    @State private var currentPageInput: String = ""
    @State private var showingAuthAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Book Info
                VStack(spacing: 8) {
                    Text(book.displayTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("Total Pages: \(book.pageCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Current Progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Page: \(book.currentPage)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ProgressView(value: book.readingProgress)
                        .progressViewStyle(LinearProgressViewStyle())

                    Text("\(book.readingProgressPercentage)% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Divider()

                // Page Input
                VStack(spacing: 16) {
                    Text("Update to page:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        TextField("Page number", text: $currentPageInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .focused($isTextFieldFocused)

                        // Microphone Button
                        Button(action: handleMicrophoneTap) {
                            ZStack {
                                Circle()
                                    .fill(speechManager.isListening ? Color.red : Color.blue)
                                    .frame(width: 56, height: 56)

                                if speechManager.isListening {
                                    Circle()
                                        .fill(Color.red.opacity(0.3))
                                        .frame(width: 56, height: 56)
                                        .scaleEffect(speechManager.isListening ? 1.3 : 1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechManager.isListening)
                                }

                                Image(systemName: speechManager.isListening ? "waveform" : "mic.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel(speechManager.isListening ? "Stop listening" : "Start voice input")
                        .accessibilityHint(speechManager.isListening ? "Stops recording your voice" : "Starts listening for page number")
                        .disabled(speechManager.authorizationStatus == .denied || speechManager.authorizationStatus == .restricted)
                    }
                    .padding(.horizontal)

                    // Voice Recognition Feedback
                    if speechManager.isListening {
                        VStack(spacing: 8) {
                            Text("Listening...")
                                .font(.caption)
                                .foregroundColor(.red)

                            if !speechManager.recognizedText.isEmpty {
                                Text(speechManager.recognizedText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .transition(.opacity)
                    }

                    // Error Message
                    if let error = speechManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Hint Text
                    if !speechManager.isListening {
                        Text("Tap the microphone and say: \"page 157\" or just \"157\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()

                // Save Button
                Button(action: saveProgress) {
                    Text("Save Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidPageNumber ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValidPageNumber)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Microphone Access Required", isPresented: $showingAuthAlert) {
                Button("Settings", action: openSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable microphone access in Settings to use voice input for page numbers.")
            }
            .errorAlert(title: "Error Saving Progress", isPresented: $showingError, message: errorMessage)
            .task {
                // Request authorization on appear
                if speechManager.authorizationStatus == .notDetermined {
                    await speechManager.requestAuthorization()
                }

                // Set initial value
                if currentPageInput.isEmpty {
                    currentPageInput = "\(book.currentPage)"
                }

                // Auto-start microphone if authorized
                if speechManager.authorizationStatus == .authorized {
                    speechManager.startListening()
                }
            }
            .onChange(of: speechManager.recognizedText) { _, newValue in
                handleRecognizedText(newValue)
            }
        }
    }

    private var isValidPageNumber: Bool {
        guard let pageNumber = Int(currentPageInput) else { return false }
        return pageNumber >= 0 && pageNumber <= book.pageCount
    }

    private func handleMicrophoneTap() {
        // Check authorization
        switch speechManager.authorizationStatus {
        case .notDetermined:
            Task {
                await speechManager.requestAuthorization()
                if speechManager.authorizationStatus == .authorized {
                    speechManager.startListening()
                }
            }
        case .denied, .restricted:
            showingAuthAlert = true
        case .authorized:
            if speechManager.isListening {
                speechManager.stopListening()
            } else {
                isTextFieldFocused = false
                speechManager.startListening()
            }
        @unknown default:
            break
        }
    }

    private func handleRecognizedText(_ text: String) {
        guard !text.isEmpty else { return }

        // Try to extract page number
        if let pageNumber = speechManager.extractPageNumber(from: text) {
            currentPageInput = "\(pageNumber)"

            // Auto-stop listening after successful recognition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speechManager.stopListening()
            }
        }
    }

    private func saveProgress() {
        guard let pageNumber = Int(currentPageInput) else { return }

        book.currentPage = Int32(pageNumber)

        // Auto-update status based on progress
        if pageNumber >= book.pageCount && book.pageCount > 0 {
            book.status = "completed"
        } else if pageNumber > 0 {
            book.status = "reading"
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save progress: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBook = Book(context: context)
    sampleBook.id = UUID()
    sampleBook.title = "The Swift Programming Language"
    sampleBook.author = "Apple Inc."
    sampleBook.pageCount = 450
    sampleBook.currentPage = 150
    sampleBook.status = "reading"

    return UpdateProgressView(book: sampleBook)
        .environment(\.managedObjectContext, context)
}
