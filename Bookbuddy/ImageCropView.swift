//
//  ImageCropView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 30/10/2025.
//

import SwiftUI

struct ImageCropView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // Crop rectangle (normalized 0-1 coordinates)
    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 3.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geometry in
                    imageView(geometry: geometry)
                }
            }
            .navigationTitle("Adjust Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        cropImage()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func imageView(geometry: GeometryProxy) -> some View {
        let imageSize = image.size
        let viewSize = geometry.size

        // Calculate fitted image size
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        let displaySize: CGSize
        if imageAspect > viewAspect {
            // Image is wider
            displaySize = CGSize(
                width: viewSize.width,
                height: viewSize.width / imageAspect
            )
        } else {
            // Image is taller
            displaySize = CGSize(
                width: viewSize.height * imageAspect,
                height: viewSize.height
            )
        }

        ZStack {
            // Image with zoom and pan
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: displaySize.width * scale, height: displaySize.height * scale)
                .offset(x: offset.width, y: offset.height)

            // Crop overlay
            CropOverlay(
                cropRect: $cropRect,
                displaySize: displaySize,
                scale: scale,
                offset: offset
            )
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let newScale = lastScale * value
                    scale = min(max(newScale, minScale), maxScale)
                }
                .onEnded { _ in
                    lastScale = scale
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
    }

    private func cropImage() {
        guard let cgImage = image.cgImage else {
            print("📸 ⚠️ Failed to get CGImage from UIImage")
            onCrop(image) // Return original if crop fails
            dismiss()
            return
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        // Convert normalized crop rect to pixel coordinates
        let cropRectPixels = CGRect(
            x: cropRect.origin.x * imageSize.width,
            y: cropRect.origin.y * imageSize.height,
            width: cropRect.width * imageSize.width,
            height: cropRect.height * imageSize.height
        )

        print("📸 Cropping image: original \(imageSize), crop \(cropRectPixels)")

        if let croppedCGImage = cgImage.cropping(to: cropRectPixels) {
            let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
            print("📸 ✅ Cropped image size: \(croppedImage.size)")
            onCrop(croppedImage)
        } else {
            print("📸 ⚠️ Failed to crop CGImage, returning original")
            onCrop(image)
        }

        dismiss()
    }
}

// MARK: - Crop Overlay
struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let displaySize: CGSize
    let scale: CGFloat
    let offset: CGSize

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size

            // Calculate actual display rect accounting for zoom and offset
            let imageFrame = CGRect(
                x: (viewSize.width - displaySize.width * scale) / 2 + offset.width,
                y: (viewSize.height - displaySize.height * scale) / 2 + offset.height,
                width: displaySize.width * scale,
                height: displaySize.height * scale
            )

            // Crop rectangle in screen coordinates
            let cropScreenRect = CGRect(
                x: imageFrame.minX + cropRect.minX * imageFrame.width,
                y: imageFrame.minY + cropRect.minY * imageFrame.height,
                width: cropRect.width * imageFrame.width,
                height: cropRect.height * imageFrame.height
            )

            ZStack {
                // Dimmed overlay outside crop area
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                Rectangle()
                                    .frame(width: cropScreenRect.width, height: cropScreenRect.height)
                                    .position(x: cropScreenRect.midX, y: cropScreenRect.midY)
                                    .blendMode(.destinationOut)
                            )
                    )

                // Crop rectangle border
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: cropScreenRect.width, height: cropScreenRect.height)
                    .position(x: cropScreenRect.midX, y: cropScreenRect.midY)

                // Grid lines
                Path { path in
                    // Vertical lines
                    let third = cropScreenRect.width / 3
                    path.move(to: CGPoint(x: cropScreenRect.minX + third, y: cropScreenRect.minY))
                    path.addLine(to: CGPoint(x: cropScreenRect.minX + third, y: cropScreenRect.maxY))
                    path.move(to: CGPoint(x: cropScreenRect.minX + 2 * third, y: cropScreenRect.minY))
                    path.addLine(to: CGPoint(x: cropScreenRect.minX + 2 * third, y: cropScreenRect.maxY))

                    // Horizontal lines
                    let thirdHeight = cropScreenRect.height / 3
                    path.move(to: CGPoint(x: cropScreenRect.minX, y: cropScreenRect.minY + thirdHeight))
                    path.addLine(to: CGPoint(x: cropScreenRect.maxX, y: cropScreenRect.minY + thirdHeight))
                    path.move(to: CGPoint(x: cropScreenRect.minX, y: cropScreenRect.minY + 2 * thirdHeight))
                    path.addLine(to: CGPoint(x: cropScreenRect.maxX, y: cropScreenRect.minY + 2 * thirdHeight))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1)

                // Corner handles
                ForEach(0..<4) { corner in
                    CropHandle(corner: corner)
                        .position(handlePosition(for: corner, in: cropScreenRect))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updateCropRect(corner: corner, translation: value.translation, imageFrame: imageFrame)
                                }
                        )
                }
            }
        }
    }

    private func handlePosition(for corner: Int, in rect: CGRect) -> CGPoint {
        switch corner {
        case 0: return CGPoint(x: rect.minX, y: rect.minY) // Top-left
        case 1: return CGPoint(x: rect.maxX, y: rect.minY) // Top-right
        case 2: return CGPoint(x: rect.minX, y: rect.maxY) // Bottom-left
        case 3: return CGPoint(x: rect.maxX, y: rect.maxY) // Bottom-right
        default: return .zero
        }
    }

    private func updateCropRect(corner: Int, translation: CGSize, imageFrame: CGRect) {
        let normalizedX = translation.width / imageFrame.width
        let normalizedY = translation.height / imageFrame.height

        var newRect = cropRect

        switch corner {
        case 0: // Top-left
            newRect.origin.x += normalizedX
            newRect.origin.y += normalizedY
            newRect.size.width -= normalizedX
            newRect.size.height -= normalizedY
        case 1: // Top-right
            newRect.origin.y += normalizedY
            newRect.size.width += normalizedX
            newRect.size.height -= normalizedY
        case 2: // Bottom-left
            newRect.origin.x += normalizedX
            newRect.size.width -= normalizedX
            newRect.size.height += normalizedY
        case 3: // Bottom-right
            newRect.size.width += normalizedX
            newRect.size.height += normalizedY
        default:
            break
        }

        // Constrain to 0-1 range
        newRect.origin.x = max(0, min(newRect.origin.x, 1))
        newRect.origin.y = max(0, min(newRect.origin.y, 1))
        newRect.size.width = max(0.1, min(newRect.size.width, 1 - newRect.origin.x))
        newRect.size.height = max(0.1, min(newRect.size.height, 1 - newRect.origin.y))

        cropRect = newRect
    }
}

// MARK: - Crop Handle
struct CropHandle: View {
    let corner: Int

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .strokeBorder(Color.black, lineWidth: 2)
            )
    }
}
