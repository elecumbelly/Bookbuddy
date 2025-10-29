//
//  PagePhotoCapture.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 29/10/2025.
//

import SwiftUI
import UIKit

struct PagePhotoCapture: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false  // Skip built-in editing, use custom options sheet
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PagePhotoCapture

        init(_ parent: PagePhotoCapture) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Prefer edited image (with markup) over original
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onCapture(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onCapture(originalImage)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
