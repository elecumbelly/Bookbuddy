//
//  BookDetailView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
internal import CoreData
import AVFoundation

struct BookDetailView: View {
    let book: Book
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingUpdateProgress = false
    @State private var showingImagePicker = false
    @State private var showingPagePhotoCapture = false
    @State private var capturedImageForCrop: IdentifiableImage? = nil
    @State private var croppedImageForPreview: IdentifiableImage? = nil
    @State private var previewImageForMarkup: IdentifiableImage? = nil
    @State private var selectedPhotoForViewing: PagePhoto? = nil
    @State private var refreshID = UUID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Book Cover and Basic Info
                HStack {
                    // Book cover - show actual image if available, otherwise placeholder
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let imageData = book.coverImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 180)
                                    .clipped()
                                    .cornerRadius(12)
                                    .accessibilityLabel("Cover image for \(book.displayTitle)")
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(12)
                                    .overlay(
                                        Image(systemName: "book.closed")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                                    .accessibilityLabel("Book cover placeholder for \(book.displayTitle)")
                            }
                        }

                        // Camera button overlay
                        Button(action: {
                            // Ensure audio session is deactivated before opening camera
                            ensureAudioSessionDeactivated()
                            showingImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .offset(x: -4, y: -4)
                        .accessibilityLabel("Take photo of book cover")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.displayTitle)
                            .font(.title2)
                            .bold()
                        
                        Text(book.displayAuthor)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if let isbn = book.isbn {
                            Text("ISBN: \(isbn)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }

                // Book Description
                if let description = book.bookDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }

                // Capture Page Button
                Button(action: {
                    // Ensure audio session is deactivated before opening camera
                    ensureAudioSessionDeactivated()
                    showingPagePhotoCapture = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Capture Page")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Capture Page")
                .accessibilityHint("Take a photo of a book page to markup and archive")
                .padding(.top, 16)

                Divider()

                // Reading Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading Status")
                        .font(.headline)
                    
                    HStack {
                        Text(book.statusEnum.displayName)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(book.statusEnum.color.opacity(0.2))
                            .foregroundColor(book.statusEnum.color)
                            .cornerRadius(8)

                        Spacer()
                    }
                }
                
                // Reading Progress
                if book.pageCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading Progress")
                            .font(.headline)
                        
                        HStack {
                            Text("Page \(book.currentPage) of \(book.pageCount)")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(book.readingProgressPercentage)%")
                                .font(.subheadline)
                                .bold()
                        }
                        
                        ProgressView(value: book.readingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Book Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    if let dateAdded = book.dateAdded {
                        HStack {
                            Text("Added:")
                            Spacer()
                            Text(dateAdded, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let publishedDate = book.publishedDate {
                        HStack {
                            Text("Published:")
                            Spacer()
                            Text(publishedDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Page Photos Archive
                VStack(alignment: .leading, spacing: 8) {
                    Text("Page Photos")
                        .font(.headline)

                    if book.pagePhotosArray.isEmpty {
                        Text("No page photos yet. Tap 'Capture Page' to add one.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                            ForEach(book.pagePhotosArray) { photo in
                                if let imageData = photo.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 140)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedPhotoForViewing = photo
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 16)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Update Progress") {
                    showingUpdateProgress = true
                }
                .accessibilityHint("Opens screen to update your current page using voice or manual input")
            }
        }
        .sheet(isPresented: $showingUpdateProgress, onDismiss: {
            // Refresh the view to reflect updated progress
            refreshID = UUID()
            viewContext.refresh(book, mergeChanges: true)
        }) {
            UpdateProgressView(book: book)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: Binding(
                get: { nil },
                set: { newImage in
                    if let newImage = newImage {
                        saveCoverImage(newImage)
                    }
                }
            ))
        }
        .fullScreenCover(isPresented: $showingPagePhotoCapture) {
            PagePhotoCapture { image in
                // Step 1: Capture → send to crop
                let identifiableImage = IdentifiableImage(image: image)
                DispatchQueue.main.async {
                    capturedImageForCrop = identifiableImage
                }
            }
        }
        .fullScreenCover(item: $capturedImageForCrop, onDismiss: {
            capturedImageForCrop = nil
        }) { identifiableImage in
            // Step 2: Crop → send to preview
            ImageCropView(
                image: identifiableImage.image,
                onCrop: { croppedImage in
                    print("📸 Image cropped, going to preview")
                    croppedImageForPreview = IdentifiableImage(image: croppedImage)
                    capturedImageForCrop = nil
                },
                onCancel: {
                    print("📸 Crop cancelled - discarding photo")
                    capturedImageForCrop = nil
                }
            )
        }
        .fullScreenCover(item: $croppedImageForPreview, onDismiss: {
            croppedImageForPreview = nil
        }) { identifiableImage in
            // Step 3: Preview with 3 buttons (Markup/Share/Save to Archive)
            CapturedPhotoOptionsSheet(
                image: identifiableImage.image,
                onSave: { finalImage in
                    print("📸 Saving from preview (direct save)")
                    savePagePhoto(finalImage)
                    croppedImageForPreview = nil
                },
                onMarkup: { imageToMarkup in
                    print("📸 Going to markup from preview")
                    previewImageForMarkup = IdentifiableImage(image: imageToMarkup)
                },
                onCancel: {
                    print("📸 Preview cancelled - discarding photo")
                    croppedImageForPreview = nil
                }
            )
        }
        .fullScreenCover(item: $previewImageForMarkup, onDismiss: {
            previewImageForMarkup = nil
        }) { identifiableImage in
            // Step 4: Markup (if user taps Markup button)
            DirectMarkupView(
                image: identifiableImage.image,
                onSave: { markedUpImage in
                    print("📸 Auto-saving marked-up image")
                    savePagePhoto(markedUpImage)
                    previewImageForMarkup = nil
                    croppedImageForPreview = nil
                },
                onCancel: {
                    print("📸 Markup cancelled - back to preview")
                    previewImageForMarkup = nil
                }
            )
        }
        .sheet(item: $selectedPhotoForViewing, onDismiss: {
            selectedPhotoForViewing = nil
        }) { photo in
            if let imageData = photo.imageData,
               let uiImage = UIImage(data: imageData) {
                PhotoViewerSheet(
                    image: uiImage,
                    dateAdded: photo.displayDate,
                    onDelete: {
                        deletePagePhoto(photo)
                        selectedPhotoForViewing = nil
                    }
                )
            } else {
                VStack {
                    Text("Unable to load photo")
                        .foregroundColor(.secondary)
                    Button("Close") {
                        selectedPhotoForViewing = nil
                    }
                }
                .padding()
            }
        }
        .id(refreshID)
    }

    // Ensure audio session is deactivated before opening camera
    // This prevents speech recognition from blocking camera audio access
    private func ensureAudioSessionDeactivated() {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category == .record || audioSession.category == .playAndRecord {
            print("🎙️ Deactivating audio session before opening camera")
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("🎙️ ✅ Audio session deactivated")
            } catch {
                print("🎙️ ⚠️ Failed to deactivate audio session: \(error.localizedDescription)")
                // Non-fatal: camera may still work
            }
        } else {
            print("🎙️ Audio session already inactive or compatible (\(audioSession.category.rawValue))")
        }
    }

    private func saveCoverImage(_ image: UIImage) {
        // Compress image to JPEG at 70% quality
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            book.coverImageData = imageData

            do {
                try viewContext.save()
                // Refresh view to show new cover
                refreshID = UUID()
                viewContext.refresh(book, mergeChanges: true)
            } catch {
                print("Failed to save cover image: \(error.localizedDescription)")
            }
        }
    }

    private func savePagePhoto(_ image: UIImage) {
        print("📸 savePagePhoto called - image size: \(image.size)")

        // Compress image to JPEG at 70% quality
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            print("📸 Image compressed to \(imageData.count) bytes")
            let pagePhoto = PagePhoto(context: viewContext)
            pagePhoto.id = UUID()
            pagePhoto.imageData = imageData
            pagePhoto.dateAdded = Date()
            pagePhoto.book = book

            print("📸 PagePhoto entity created, saving to Core Data...")

            do {
                try viewContext.save()
                print("📸 ✅ Successfully saved to Core Data!")
                print("📸 Book now has \(book.pagePhotosArray.count) photos")

                // Refresh view to show new photo
                refreshID = UUID()
                viewContext.refresh(book, mergeChanges: true)
                print("📸 View refreshed with new refreshID")
            } catch {
                print("📸 ❌ Failed to save page photo: \(error.localizedDescription)")
            }
        } else {
            print("📸 ❌ Failed to compress image to JPEG")
        }
    }

    private func deletePagePhoto(_ photo: PagePhoto) {
        viewContext.delete(photo)

        do {
            try viewContext.save()
            // Refresh view
            refreshID = UUID()
            viewContext.refresh(book, mergeChanges: true)
        } catch {
            print("Failed to delete page photo: \(error.localizedDescription)")
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBook = Book(context: context)
    sampleBook.id = UUID()
    sampleBook.title = "The Swift Programming Language"
    sampleBook.author = "Apple Inc."
    sampleBook.isbn = "9780134610993"
    sampleBook.publishedDate = Date()
    sampleBook.dateAdded = Date()
    sampleBook.pageCount = 450
    sampleBook.currentPage = 150
    sampleBook.status = "reading"
    
    return NavigationView {
        BookDetailView(book: sampleBook)
    }
    .environment(\.managedObjectContext, context)
}
