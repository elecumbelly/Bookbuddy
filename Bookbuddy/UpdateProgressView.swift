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

    @State private var autoSaveCountdown: Int? = nil
    @State private var autoSaveTask: Task<Void, Never>? = nil
    @State private var lastMicTapTime: Date? = nil

    var body: some View {
        NavigationStack {
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
                                    .fill(microphoneButtonColor)
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
                        .disabled(isMicrophoneDisabled)
                        .opacity(isMicrophoneDisabled ? 0.5 : 1.0)
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

                    // Authorization Status Debug
                    Text("Auth: \(authStatusText)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Error Message
                    if let error = speechManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Auto-save countdown
                    if let countdown = autoSaveCountdown {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Auto-saving in \(countdown)...")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Button("Cancel") {
                                cancelAutoSaveCountdown()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }

                    // Hint Text
                    if !speechManager.isListening && autoSaveCountdown == nil {
                        Text("Tap the microphone and say: \"page 157\" or just \"157\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
                // Set initial value
                if currentPageInput.isEmpty {
                    currentPageInput = "\(book.currentPage)"
                }

                // Request authorization on appear if needed
                if speechManager.authorizationStatus == .notDetermined {
                    await speechManager.requestAuthorization()
                }

                // ⚠️ IMPORTANT: Auto-start microphone is REQUIRED by user workflow
                // User wants hands-free operation - mic starts automatically, button is only
                // used to stop/restart if speech recognition gets it wrong.
                // DO NOT REMOVE this auto-start behavior! (See v0.5.2 regression)
                if speechManager.authorizationStatus == .authorized {
                    print("🎙️ Auto-starting microphone")
                    // Small delay to ensure authorization is fully processed
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    speechManager.startListening()
                }
            }
            .onChange(of: speechManager.recognizedText) { _, newValue in
                handleRecognizedText(newValue)
            }
            .onChange(of: currentPageInput) { _, _ in
                // Cancel auto-save if user manually edits the page number
                if isTextFieldFocused {
                    cancelAutoSaveCountdown()
                }
            }
            .onDisappear {
                // Clean up countdown task when view disappears
                cancelAutoSaveCountdown()

                // Stop speech recognition to free audio session for camera
                if speechManager.isListening {
                    speechManager.stopListening()
                }
            }
        }
    }

    private var isValidPageNumber: Bool {
        guard let pageNumber = Int(currentPageInput) else { return false }
        return pageNumber >= 0 && pageNumber <= book.pageCount
    }

    private var isMicrophoneDisabled: Bool {
        return speechManager.authorizationStatus == .denied ||
               speechManager.authorizationStatus == .restricted
    }

    private var microphoneButtonColor: Color {
        if isMicrophoneDisabled {
            return Color.gray
        } else if speechManager.isListening {
            return Color.red
        } else {
            return Color.blue
        }
    }

    private var authStatusText: String {
        switch speechManager.authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }

    private func handleMicrophoneTap() {
        print("🎙️ Mic button tapped")

        // ⚠️ CRITICAL: DO NOT ADD HAPTIC FEEDBACK HERE!
        // UIImpactFeedbackGenerator blocks the main thread on devices without haptic support,
        // causing "System gesture gate timed out" errors that break ALL gesture recognition
        // (mic button, document scanner crop handles, etc.). See v0.5.2 → v0.5.3 regression.
        // Reference: .agent/.agentknown-issues.md

        // Debounce: ignore rapid taps within 0.3 seconds
        if let lastTap = lastMicTapTime,
           Date().timeIntervalSince(lastTap) < 0.3 {
            print("🎙️ Debounced - ignoring tap")
            return
        }
        lastMicTapTime = Date()

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

            // Start auto-save countdown
            startAutoSaveCountdown()
        }
    }

    private func startAutoSaveCountdown() {
        // Cancel any existing countdown
        cancelAutoSaveCountdown()

        // Start countdown from 5 seconds
        autoSaveCountdown = 5

        autoSaveTask = Task {
            for i in stride(from: 5, through: 1, by: -1) {
                autoSaveCountdown = i
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Check if task was cancelled
                if Task.isCancelled {
                    return
                }
            }

            // Countdown complete - save progress
            await MainActor.run {
                if isValidPageNumber {
                    saveProgress()
                }
                autoSaveCountdown = nil
            }
        }
    }

    private func cancelAutoSaveCountdown() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
        autoSaveCountdown = nil
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
