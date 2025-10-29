# Bookbuddy Project Overview

**Generated:** October 27, 2025
**Last Updated:** Version 0.4 - Full Feature Set

## Project Summary

**Bookbuddy** is a SwiftUI-based iOS application for personal book collection management, featuring barcode scanning, voice-enabled progress tracking, and photo capture with markup capabilities.

## Current State - Version 0.4 ✅

### Implemented Features
- ✅ **Barcode Scanner**: Camera-based ISBN scanning with real-time detection
- ✅ **Book Lookup**: Automatic metadata fetching from Open Library API
- ✅ **Voice Progress**: Hands-free reading progress updates with speech recognition
- ✅ **Photo Capture**: Take photos of book pages with PencilKit markup tools
- ✅ **Photo Archive**: Store and view marked-up page photos with zoom
- ✅ **Reading Progress**: Visual progress bars and percentage tracking
- ✅ **Book Management**: Full CRUD operations with Core Data persistence

## Core Technologies

- **Platform:** iOS 17.0+ (SwiftUI)
- **Data Layer:** Core Data with Book and PagePhoto entities
- **Concurrency:** Swift Concurrency (async/await)
- **Speech:** iOS Speech framework for voice input
- **Camera:** AVFoundation for barcode scanning and photo capture
- **Drawing:** PencilKit for photo markup and annotations
- **Networking:** URLSession with async/await for API calls

## Architecture

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
│   ├── Persistence.swift              # Core Data stack with error handling
│   ├── Book.swift                     # Book entity model
│   ├── PagePhoto.swift                # Page photo entity model
│   └── Bookbuddy.xcdatamodeld        # Data model schema
├── Views
│   ├── ContentView.swift              # Library list view
│   ├── BookDetailView.swift           # Book details with photo archive
│   ├── BookRowView.swift              # List row component
│   ├── AddBookView.swift              # Add/edit book with scanner
│   ├── UpdateProgressView.swift       # Voice progress updates
│   ├── PhotoViewerSheet.swift         # Full-screen photo viewer
│   ├── CapturedPhotoOptionsSheet.swift # Photo capture flow
│   └── PagePhotoCapture.swift         # Camera integration
├── Managers
│   ├── SpeechRecognitionManager.swift # Voice recognition engine
│   ├── BarcodeScannerView.swift       # ISBN barcode scanner
│   └── BarcodeScannerOverlay.swift    # Scanner UI overlay
├── Utilities
│   ├── ErrorAlertModifier.swift       # Reusable error alerts
│   ├── ShareSheet.swift               # iOS share functionality
│   └── IdentifiableImage.swift        # UIImage wrapper for sheets
└── Documentation
    ├── README.md                      # User-facing documentation
    ├── claude.md                      # This file - technical overview
    └── .agent/                        # Agent context files
```

## Data Model

### Book Entity
| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | No | Unique identifier |
| title | String | Yes | Book title |
| author | String | Yes | Author name |
| isbn | String | Yes | ISBN-10 or ISBN-13 |
| publishedDate | Date | Yes | Publication date |
| pageCount | Int32 | No | Total pages (default: 0) |
| currentPage | Int32 | No | Current reading position |
| dateAdded | Date | Yes | When book was added |
| coverImageData | Binary | Yes | Cover image (compressed JPEG) |
| bookDescription | String | Yes | Book description/summary |
| status | String | Yes | "to-read", "reading", "completed" |
| pagePhotos | Relationship | Yes | One-to-many to PagePhoto |

### PagePhoto Entity
| Attribute | Type | Optional | Description |
|-----------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| imageData | Binary | Yes | Photo data (compressed JPEG) |
| dateAdded | Date | Yes | When photo was captured |
| book | Relationship | Yes | Many-to-one to Book |

## Key Implementation Details

### ISBN Validation
- **ISBN-10**: Modulus 11 check digit algorithm
- **ISBN-13**: Modulus 10 check digit with 1-3 weighting
- Real-time validation with visual feedback

### Barcode Scanning
- Supported formats: EAN-13, EAN-8, UPC-E, Code 128, Code 39
- Debouncing to prevent duplicate scans
- Haptic feedback on successful scan

### Voice Recognition
- Auto-start microphone on screen load
- Recognizes "page 157", "157", or spelled numbers
- Auto-save countdown with cancellation
- Permission handling with fallback to manual entry

### Photo Capture & Markup
- PencilKit integration for professional drawing tools
- Pinch-to-zoom (1x-5x) during markup
- Save marked-up version (not original)
- Photo archive with thumbnail grid
- Full-screen viewer with zoom capability

### Image Optimization
- JPEG compression at 70% quality
- Reduces typical images from ~500KB to ~50-100KB
- External storage for Core Data binary attributes

## Version History

### v0.4 (Current)
- Page photo capture with camera
- PencilKit markup tools
- Photo archive and viewer
- Zoom in markup and viewer modes

### v0.3
- Voice progress updates with speech recognition
- Photo cover capture for books

### v0.2.1
- Bug fixes for toolbar buttons and UI spacing
- Progress bar refresh improvements

### v0.2
- iOS 26 compatibility fixes
- Accessibility improvements
- Memory management optimization

### v0.1
- Initial barcode scanner implementation
- ISBN lookup and validation
- Book CRUD operations

## Development Notes

### Testing Requirements
- **Real device required** for barcode scanning and voice recognition
- Simulator does not support camera or microphone
- iOS 17.0+ required for all features

### Permissions Required
- **Camera**: Barcode scanning and photo capture
- **Microphone**: Voice input for progress updates
- **Speech Recognition**: Understanding spoken page numbers

### Known Limitations
- Barcode scanning doesn't work in iOS Simulator
- Some older books may lack metadata in Open Library
- Cover images may not be available for all books

## Future Considerations

### Potential Enhancements
- Export library to CSV/PDF
- Reading statistics and charts
- Book notes and highlights
- Social sharing features
- Dark mode theming
- iPad optimization
- Additional book APIs (Google Books, Goodreads)

### Technical Debt
- Consider extracting image compression to utility
- Evaluate folder organization for better structure
- Standardize CoreData import statements
- Add comprehensive error logging
