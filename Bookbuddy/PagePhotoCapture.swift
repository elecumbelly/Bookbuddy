//
//  PagePhotoCapture.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 29/10/2025.
//

import SwiftUI
import UIKit
import VisionKit

struct PagePhotoCapture: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentCamera = VNDocumentCameraViewController()
        documentCamera.delegate = context.coordinator
        return documentCamera
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: PagePhotoCapture

        init(_ parent: PagePhotoCapture) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Get the first scanned page (most recent)
            guard scan.pageCount > 0 else {
                parent.dismiss()
                return
            }

            // VNDocumentCameraScan returns already cropped and perspective-corrected image
            let scannedImage = scan.imageOfPage(at: 0)
            parent.onCapture(scannedImage)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            // Handle error gracefully - just dismiss
            parent.dismiss()
        }
    }
}
