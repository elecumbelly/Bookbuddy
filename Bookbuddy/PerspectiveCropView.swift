//
//  PerspectiveCropView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 30/10/2025.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct PerspectiveCropView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    // Corner positions (normalized 0-1 coordinates)
    @State private var topLeft: CGPoint = CGPoint(x: 0.1, y: 0.1)
    @State private var topRight: CGPoint = CGPoint(x: 0.9, y: 0.1)
    @State private var bottomLeft: CGPoint = CGPoint(x: 0.1, y: 0.9)
    @State private var bottomRight: CGPoint = CGPoint(x: 0.9, y: 0.9)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geometry in
                    perspectiveView(geometry: geometry)
                }
            }
            .navigationTitle("Adjust Perspective")
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
                        applyCrop()
                    }
                }
            }
        }
    }

    private func perspectiveView(geometry: GeometryProxy) -> some View {
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

        let imageFrame = CGRect(
            x: (viewSize.width - displaySize.width) / 2,
            y: (viewSize.height - displaySize.height) / 2,
            width: displaySize.width,
            height: displaySize.height
        )

        return ZStack {
            // Image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: displaySize.width, height: displaySize.height)
                .position(x: viewSize.width / 2, y: viewSize.height / 2)

            // Perspective overlay
            PerspectiveOverlay(
                topLeft: $topLeft,
                topRight: $topRight,
                bottomLeft: $bottomLeft,
                bottomRight: $bottomRight,
                imageFrame: imageFrame
            )
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    private func applyCrop() {
        print("📸 Applying perspective correction...")

        guard let ciImage = CIImage(image: image) else {
            print("📸 ⚠️ Failed to create CIImage")
            onCrop(image)
            dismiss()
            return
        }

        let imageSize = ciImage.extent.size

        // Convert normalized coordinates to image coordinates
        let tl = CIVector(x: topLeft.x * imageSize.width, y: (1 - topLeft.y) * imageSize.height)
        let tr = CIVector(x: topRight.x * imageSize.width, y: (1 - topRight.y) * imageSize.height)
        let bl = CIVector(x: bottomLeft.x * imageSize.width, y: (1 - bottomLeft.y) * imageSize.height)
        let br = CIVector(x: bottomRight.x * imageSize.width, y: (1 - bottomRight.y) * imageSize.height)

        print("📸 Corner points: TL\(tl) TR\(tr) BL\(bl) BR\(br)")

        // Apply perspective correction
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = ciImage
        filter.topLeft = tl
        filter.topRight = tr
        filter.bottomLeft = bl
        filter.bottomRight = br

        guard let outputImage = filter.outputImage else {
            print("📸 ⚠️ Perspective correction failed")
            onCrop(image)
            dismiss()
            return
        }

        // Render to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("📸 ⚠️ Failed to create CGImage")
            onCrop(image)
            dismiss()
            return
        }

        let correctedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        print("📸 ✅ Perspective corrected, size: \(correctedImage.size)")

        onCrop(correctedImage)
        dismiss()
    }
}

// MARK: - Perspective Overlay
struct PerspectiveOverlay: View {
    @Binding var topLeft: CGPoint
    @Binding var topRight: CGPoint
    @Binding var bottomLeft: CGPoint
    @Binding var bottomRight: CGPoint
    let imageFrame: CGRect

    var body: some View {
        ZStack {
            // Dimmed overlay
            Color.black.opacity(0.5)

            // Perspective quad
            PerspectiveQuad(
                topLeft: screenPoint(topLeft),
                topRight: screenPoint(topRight),
                bottomLeft: screenPoint(bottomLeft),
                bottomRight: screenPoint(bottomRight)
            )
            .stroke(Color.white, lineWidth: 2)

            // Grid lines
            PerspectiveGrid(
                topLeft: screenPoint(topLeft),
                topRight: screenPoint(topRight),
                bottomLeft: screenPoint(bottomLeft),
                bottomRight: screenPoint(bottomRight)
            )
            .stroke(Color.white.opacity(0.5), lineWidth: 1)

            // Corner handles
            cornerHandle(for: $topLeft, label: "TL")
            cornerHandle(for: $topRight, label: "TR")
            cornerHandle(for: $bottomLeft, label: "BL")
            cornerHandle(for: $bottomRight, label: "BR")
        }
    }

    private func screenPoint(_ normalizedPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: imageFrame.minX + normalizedPoint.x * imageFrame.width,
            y: imageFrame.minY + normalizedPoint.y * imageFrame.height
        )
    }

    private func normalizedPoint(_ screenPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: max(0, min(1, (screenPoint.x - imageFrame.minX) / imageFrame.width)),
            y: max(0, min(1, (screenPoint.y - imageFrame.minY) / imageFrame.height))
        )
    }

    @ViewBuilder
    private func cornerHandle(for point: Binding<CGPoint>, label: String) -> some View {
        let screenPos = screenPoint(point.wrappedValue)

        Circle()
            .fill(Color.white)
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .strokeBorder(Color.blue, lineWidth: 3)
            )
            .overlay(
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.blue)
            )
            .position(screenPos)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        point.wrappedValue = normalizedPoint(value.location)
                    }
            )
    }
}

// MARK: - Perspective Quad Shape
struct PerspectiveQuad: Shape {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        return path
    }
}

// MARK: - Perspective Grid
struct PerspectiveGrid: Shape {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Horizontal lines (thirds)
        for i in 1...2 {
            let ratio = CGFloat(i) / 3.0
            let left = interpolate(from: topLeft, to: bottomLeft, ratio: ratio)
            let right = interpolate(from: topRight, to: bottomRight, ratio: ratio)
            path.move(to: left)
            path.addLine(to: right)
        }

        // Vertical lines (thirds)
        for i in 1...2 {
            let ratio = CGFloat(i) / 3.0
            let top = interpolate(from: topLeft, to: topRight, ratio: ratio)
            let bottom = interpolate(from: bottomLeft, to: bottomRight, ratio: ratio)
            path.move(to: top)
            path.addLine(to: bottom)
        }

        return path
    }

    private func interpolate(from p1: CGPoint, to p2: CGPoint, ratio: CGFloat) -> CGPoint {
        CGPoint(
            x: p1.x + (p2.x - p1.x) * ratio,
            y: p1.y + (p2.y - p1.y) * ratio
        )
    }
}
