//
//  PhotoViewerSheet.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 29/10/2025.
//

import SwiftUI

struct PhotoViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let dateAdded: String
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Zoomable Photo
                ZoomableImageView(image: image)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.05))

                // Date added
                Text("Captured: \(dateAdded)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Page Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("This photo will be permanently deleted.")
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [image])
            }
        }
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        context.coordinator.imageView = imageView

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image

        // Layout on next run loop when bounds are available
        DispatchQueue.main.async {
            self.layoutScrollView(scrollView, coordinator: context.coordinator)
        }
    }

    private func layoutScrollView(_ scrollView: UIScrollView, coordinator: Coordinator) {
        guard let imageView = coordinator.imageView,
              scrollView.bounds.width > 0,
              scrollView.bounds.height > 0 else { return }

        imageView.frame = scrollView.bounds
        scrollView.contentSize = scrollView.bounds.size
        scrollView.zoomScale = 1.0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
    }
}
