# 📚 BookBuddy

**A modern iOS app for managing your personal book collection with voice-enabled progress tracking and barcode scanning.**

Perfect for bedtime readers who want to quickly log their reading progress or scan new books to add to their library.

---

## ✨ Features

### 📖 Book Management
- **Barcode Scanner**: Point your camera at any ISBN barcode to instantly add books
- **ISBN Lookup**: Automatic book metadata fetching from Open Library API
- **Manual Entry**: Add books manually if barcode/ISBN isn't available
- **Cover Images**: Automatically downloads and stores book cover art
- **Rich Metadata**: Title, author, page count, description, publication date

### 🎤 Voice-Enabled Progress Tracking
- **Hands-Free Updates**: Say "page 157" before bed to update your reading progress
- **Auto-Start Microphone**: One tap and you're ready to speak
- **Smart Recognition**: Understands "page 157", "157", or spelled numbers
- **Reading Status**: Automatically tracks To Read → Reading → Completed

### 📊 Reading Progress
- **Visual Progress Bars**: See completion percentage at a glance
- **Current Page Tracking**: Know exactly where you left off
- **Reading Statistics**: Track which books you're reading and which are complete

### 📸 Page Photo Capture & Markup
- **Document Scanner**: Apple's VNDocumentCameraViewController with automatic edge detection
- **Perspective Crop**: Optional 4-corner keystone correction for perfect page alignment
- **Page Photography**: Capture photos of interesting book pages with professional scanning
- **PencilKit Markup**: Annotate with pen, pencil, highlighter, eraser, and ruler
- **Pinch-to-Zoom**: Zoom up to 5x during markup for precise annotations
- **Photo Archive**: Store and organize all your page photos by book
- **Zoomable Viewer**: View archived photos with full zoom capability
- **Share & Delete**: Share marked-up photos or remove from archive

---

## 🏗️ Architecture

### Tech Stack
- **Platform**: iOS 17.0+ (SwiftUI)
- **Data Layer**: Core Data for local persistence
- **Networking**: URLSession with async/await
- **Speech Recognition**: iOS Speech framework
- **Camera**: AVFoundation for barcode scanning

### Design Pattern
- **MVVM** with SwiftUI reactive bindings
- **Separation of Concerns**: Views, Managers, Models
- **Reactive Data**: @FetchRequest, @StateObject, @ObservedObject
- **Modern Swift**: async/await, Combine, Swift Concurrency

### Project Structure
```
Bookbuddy/
├── App Entry
│   └── BookbuddyApp.swift
├── Core Data
│   ├── Persistence.swift         # Core Data stack
│   ├── Book.swift                # Book entity model
│   └── Bookbuddy.xcdatamodeld    # Data model schema
├── Views
│   ├── ContentView.swift         # Library list view
│   ├── BookDetailView.swift      # Book details
│   ├── BookRowView.swift         # List row component
│   ├── AddBookView.swift         # Add/edit book with scanner
│   └── UpdateProgressView.swift  # Voice progress updates
├── Managers
│   ├── SpeechRecognitionManager.swift    # Voice recognition
│   ├── BarcodeScannerView.swift          # Camera scanner
│   └── BarcodeScannerOverlay.swift       # Scanner UI
└── Assets
    └── Assets.xcassets/          # App icons, images
```

---

## 🚀 Getting Started

### Prerequisites
- **macOS** 14.0+ (Sonoma) with Xcode 17.0+
- **iOS Device** (iPhone or iPad) running iOS 17.0+
- **Apple Developer Account** (for device testing)

> ⚠️ **Note**: Barcode scanning and voice recognition require a real iOS device. These features don't work in the iOS Simulator.

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/elecumbelly/Bookbuddy.git
   cd Bookbuddy
   ```

2. **Open in Xcode**
   ```bash
   open Bookbuddy.xcodeproj
   ```

3. **Configure signing**
   - Select the Bookbuddy target
   - Go to "Signing & Capabilities"
   - Select your development team

4. **Connect your iPhone**
   - Connect via USB
   - Select your device in Xcode's device menu

5. **Build and run**
   - Press `Cmd+R` or click the Play button
   - Grant permissions when prompted:
     - Camera access (for barcode scanning)
     - Microphone access (for voice input)
     - Speech recognition (for understanding spoken numbers)

---

## 📱 How to Use

### Adding a Book

**Method 1: Barcode Scan (Recommended)**
1. Tap the **+** button
2. Point your camera at the ISBN barcode (usually on the back cover)
3. Wait for the haptic buzz
4. Review auto-filled information
5. Tap **Save**

**Method 2: Manual ISBN Entry**
1. Tap the **+** button
2. Type the ISBN number in the text field
3. Lookup automatically triggers for valid ISBNs
4. Review and edit as needed
5. Tap **Save**

**Method 3: Completely Manual**
1. Tap the **+** button
2. Fill in Title and Author (required)
3. Optionally add page count, description, date
4. Tap **Add Book Manually**

### Tracking Reading Progress

1. Open a book from your library
2. Tap **Update Progress** in the top right
3. **Voice input** (easiest):
   - Microphone starts automatically
   - Say "page 157" (or just "157")
   - Tap **Save Progress**
4. **Manual input** (alternative):
   - Type page number
   - Tap **Save Progress**

### Capturing Page Photos

1. Open a book from your library
2. Tap **Capture Page** button
3. Document scanner opens automatically with edge detection
4. Position the page and tap capture
5. **Preview screen** appears with 4 options:
   - **Adjust Crop**: Fine-tune perspective with 4-corner keystone correction (optional)
   - **Markup**: Annotate with pen, pencil, highlighter, eraser, ruler (optional)
   - **Share**: Share the photo via iOS share sheet
   - **Save to Archive**: Keep the photo with your book
6. Use markup tools if desired:
   - Pinch to zoom for precise annotations
   - Tap Done when finished - auto-saves to archive
7. Or save directly from preview without editing

### Viewing Page Photos

1. Scroll to the bottom of any book's detail page
2. Tap any thumbnail to view full-screen
3. Pinch to zoom for better detail
4. Share or delete photos as needed

### Managing Your Library

- **View all books**: Scroll through your library on the main screen
- **See book details**: Tap any book
- **Delete books**: Swipe left on any book → Delete
- **Edit mode**: Tap Edit button to manage multiple books

---

## 🔐 Permissions

BookBuddy requests the following permissions:

| Permission | Purpose | When Requested |
|------------|---------|----------------|
| **Camera** | Scan ISBN barcodes on books | First time you open Add Book screen |
| **Microphone** | Voice input for page numbers | First time you tap mic button in Update Progress |
| **Speech Recognition** | Understand spoken page numbers | First time you use voice input |

All permissions can be revoked in **Settings → Privacy → [Permission Type]**.

---

## 🛠️ Development

### Building from Source

```bash
# Clean build folder
xcodebuild clean -project Bookbuddy.xcodeproj

# Build for device
xcodebuild -project Bookbuddy.xcodeproj \
  -scheme Bookbuddy \
  -destination 'platform=iOS,id=<DEVICE_ID>' \
  build
```

### Core Data Model

The app uses Core Data with `Book` and `PagePhoto` entities:

**Book Entity:**
| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | No | Unique identifier |
| title | String | Yes | Book title |
| author | String | Yes | Author name |
| isbn | String | Yes | ISBN-10 or ISBN-13 |
| publishedDate | Date | Yes | Publication date |
| pageCount | Int32 | No | Total pages (default: 0) |
| currentPage | Int32 | No | Current reading position (default: 0) |
| dateAdded | Date | Yes | When book was added |
| coverImageData | Binary | Yes | Cover image (JPEG data, 70% quality) |
| bookDescription | String | Yes | Book description/summary |
| status | String | Yes | "to-read", "reading", "completed" |
| pagePhotos | Relationship | Yes | One-to-many to PagePhoto |

**PagePhoto Entity:**
| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| imageData | Binary | Yes | Photo data (JPEG, 70% quality) |
| dateAdded | Date | Yes | When photo was captured |
| book | Relationship | Yes | Many-to-one to Book |

### ISBN Validation

BookBuddy implements proper ISBN checksum validation:
- **ISBN-10**: Modulus 11 check digit algorithm
- **ISBN-13**: Modulus 10 check digit algorithm with 1-3 weighting

### Barcode Support

Supported barcode formats for ISBN scanning:
- EAN-13 (most common for ISBN-13)
- EAN-8 (some international books)
- UPC-E
- Code 128 (alternative ISBN format)
- Code 39 (legacy ISBN-10)

---

## 🤝 Contributing

This is a personal learning project, but suggestions and feedback are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- **Open Library API** for book metadata
- **Apple Speech Framework** for voice recognition
- **AVFoundation** for barcode scanning
- **Claude Code** for development assistance

---

## 🐛 Known Issues

- Barcode scanning doesn't work in iOS Simulator (use real device)
- Some older books may not have metadata in Open Library
- Cover images may not be available for all books

---

## 🗺️ Roadmap

### Completed (v0.1 - v0.5.4)
- [x] Barcode scanning for ISBN lookup
- [x] Voice-enabled progress updates
- [x] Document scanner with automatic edge detection
- [x] Perspective crop with 4-corner keystone correction
- [x] Page photo capture with markup
- [x] Photo archive and viewer
- [x] Zoom functionality for markup and viewing

### Future Features
- [ ] Export library to CSV/PDF
- [ ] Reading statistics and charts
- [ ] Book recommendations
- [ ] Notes and highlights per book
- [ ] Share book recommendations with friends
- [ ] Dark mode theming
- [ ] iPad optimization with split view
- [ ] Goodreads integration
- [ ] Book clubs and social features
- [ ] Reading goals and challenges

---

## 📧 Contact

Stephen Spence - [@elecumbelly](https://github.com/elecumbelly)

Project Link: [https://github.com/elecumbelly/Bookbuddy](https://github.com/elecumbelly/Bookbuddy)

---

**Made with ❤️ and 📚 for book lovers everywhere**
