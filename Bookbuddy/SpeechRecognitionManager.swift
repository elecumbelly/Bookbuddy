//
//  SpeechRecognitionManager.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import Foundation
import SwiftUI
import Combine
import Speech
import AVFoundation

@MainActor
class SpeechRecognitionManager: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    func requestAuthorization() async {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        authorizationStatus = status
    }

    func startListening() {
        print("🎙️ startListening() called")
        guard !isListening else {
            print("🎙️ Already listening - returning")
            return
        }

        // Cancel any ongoing recognition
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            print("🎙️ Configuring audio session...")
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("🎙️ Audio session configured")
        } catch {
            print("🎙️ ❌ Audio session error: \(error.localizedDescription)")
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request"
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Get audio input
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false

            if let result = result {
                Task { @MainActor in
                    self.recognizedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }

        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            recognizedText = ""
            errorMessage = nil
            print("🎙️ ✅ Audio engine started - now listening!")
        } catch {
            print("🎙️ ❌ Audio engine error: \(error.localizedDescription)")
            errorMessage = "Audio engine error: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        print("🎙️ stopListening() called")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        isListening = false
        recognitionRequest = nil
        recognitionTask = nil
        print("🎙️ Stopped listening")
    }

    // Extract page number from spoken text
    func extractPageNumber(from text: String) -> Int? {
        let lowercased = text.lowercased()

        // Remove common words
        let cleaned = lowercased
            .replacingOccurrences(of: "page", with: "")
            .replacingOccurrences(of: "to", with: "")
            .replacingOccurrences(of: "number", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Try to find numbers in the text
        let components = cleaned.components(separatedBy: .whitespaces)

        // Look for numeric values
        for component in components {
            if let number = Int(component) {
                return number
            }
        }

        // Try to parse spelled-out numbers
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .spellOut

        for component in components {
            if let number = numberFormatter.number(from: component) {
                return number.intValue
            }
        }

        return nil
    }
}
