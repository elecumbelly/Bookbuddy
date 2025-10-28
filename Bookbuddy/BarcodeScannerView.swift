//
//  BarcodeScannerView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    var onBarcodeDetected: ((String) -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let captureSession = AVCaptureSession()
        context.coordinator.captureSession = captureSession

        // Set up camera
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        // Set up metadata output for barcode detection
        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)

            // Support ISBN barcode formats
            metadataOutput.metadataObjectTypes = [
                .ean13,    // Most common for ISBN-13
                .ean8,     // Some books
                .upce,     // UPC format
                .code128,  // Alternative ISBN format
                .code39,   // Legacy ISBN-10
            ]
        } else {
            return view
        }

        // Set up preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if needed
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.layer.bounds
            }
        }

        // Control scanning state
        if isScanning {
            if context.coordinator.captureSession?.isRunning == false {
                DispatchQueue.global(qos: .userInitiated).async {
                    context.coordinator.captureSession?.startRunning()
                }
            }
        } else {
            if context.coordinator.captureSession?.isRunning == true {
                DispatchQueue.global(qos: .userInitiated).async {
                    context.coordinator.captureSession?.stopRunning()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, isScanning: $isScanning, onBarcodeDetected: onBarcodeDetected)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureSession?.stopRunning()
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedCode: String
        @Binding var isScanning: Bool
        var onBarcodeDetected: ((String) -> Void)?
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var lastScannedCode: String?
        var lastScanTime: Date?

        init(scannedCode: Binding<String>, isScanning: Binding<Bool>, onBarcodeDetected: ((String) -> Void)?) {
            self._scannedCode = scannedCode
            self._isScanning = isScanning
            self.onBarcodeDetected = onBarcodeDetected
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            // Ensure we're scanning
            guard isScanning else { return }

            // Find first valid barcode
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }

                // Debounce: Ignore if same code scanned within 2 seconds
                if let lastCode = lastScannedCode,
                   let lastTime = lastScanTime,
                   lastCode == stringValue,
                   Date().timeIntervalSince(lastTime) < 2.0 {
                    return
                }

                // Validate it looks like an ISBN (10 or 13 digits)
                let digitsOnly = stringValue.filter { $0.isNumber }
                guard digitsOnly.count == 10 || digitsOnly.count == 13 else {
                    return
                }

                // Update state
                lastScannedCode = stringValue
                lastScanTime = Date()

                // Haptic feedback
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

                // Notify
                DispatchQueue.main.async {
                    self.scannedCode = stringValue
                    self.onBarcodeDetected?(stringValue)

                    // Pause scanning briefly
                    self.isScanning = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.isScanning = true
                    }
                }
            }
        }
    }
}

// Camera permission helper
struct CameraPermissionHelper {
    static func checkPermission() async -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        if status == .notDetermined {
            // Request permission
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }

        return status
    }
}
