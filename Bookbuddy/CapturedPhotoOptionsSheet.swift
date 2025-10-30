//
//  CapturedPhotoOptionsSheet.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 29/10/2025.
//

import SwiftUI
import PencilKit

struct CapturedPhotoOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage
    @State private var showingMarkup = false
    @State private var showingShareSheet = false

    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    init(image: UIImage, onSave: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self._image = State(initialValue: image)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Photo preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .padding()

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingMarkup = true
                    }) {
                        HStack {
                            Image(systemName: "pencil.tip.crop.circle")
                            Text("Markup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        print("📸 'Save to Archive' button tapped")
                        print("📸 Image size being saved: \(image.size)")
                        // Pass the current image (with markup if applied)
                        onSave(image)
                        print("📸 onSave callback completed, calling dismiss()")
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Archive")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
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
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMarkup) {
                MarkupViewController(image: $image)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [image])
            }
        }
    }
}

// MARK: - Markup View Controller
struct MarkupViewController: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage

    func makeUIViewController(context: Context) -> UINavigationController {
        let markupVC = MarkupHostingController(image: image) { editedImage in
            print("📸 Markup completed - edited image size: \(editedImage.size)")
            context.coordinator.parent.image = editedImage
            print("📸 Updated binding with edited image")
            context.coordinator.parent.dismiss()
        } onCancel: {
            print("📸 Markup cancelled")
            context.coordinator.parent.dismiss()
        }

        let navController = UINavigationController(rootViewController: markupVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: MarkupViewController

        init(_ parent: MarkupViewController) {
            self.parent = parent
        }
    }
}

class MarkupHostingController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver, UIScrollViewDelegate {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    private var scrollView: UIScrollView!
    private var containerView: UIView!
    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    private var imageView: UIImageView!

    init(image: UIImage, onSave: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.originalImage = image
        self.onSave = onSave
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Markup"

        // Scroll view for zooming
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Container view to hold image and canvas together
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)

        // Image view as background
        imageView = UIImageView(image: originalImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)

        // Canvas view for drawing
        canvasView = PKCanvasView()
        canvasView.delegate = self
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(canvasView)

        NSLayoutConstraint.activate([
            // Scroll view fills the safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Container matches scroll view size
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Image view fills container
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Canvas overlays image
            canvasView.topAnchor.constraint(equalTo: imageView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])

        // Tool picker
        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }

    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    @objc private func cancelTapped() {
        onCancel()
    }

    @objc private func doneTapped() {
        print("📸 Markup 'Done' tapped - merging image with drawing")
        // Merge the drawing with the image at original resolution
        let imageSize = originalImage.size
        print("📸 Original image size: \(imageSize)")

        // Calculate scale factor between display size and original image size
        let displaySize = imageView.bounds.size
        let scaleX = imageSize.width / displaySize.width
        let scaleY = imageSize.height / displaySize.height
        let scaleFactor = max(scaleX, scaleY)
        print("📸 Scale factor: \(scaleFactor)")

        // Render at original image size to preserve quality
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let mergedImage = renderer.image { context in
            // Draw original image at full size
            originalImage.draw(in: CGRect(origin: .zero, size: imageSize))

            // Scale and draw the canvas drawing to match original image size
            let drawing = canvasView.drawing
            let drawingImage = drawing.image(from: canvasView.bounds, scale: scaleFactor)
            drawingImage.draw(in: CGRect(origin: .zero, size: imageSize))
        }

        print("📸 Merged image created, size: \(mergedImage.size)")
        print("📸 Calling onSave with merged image")
        onSave(mergedImage)
    }
}
