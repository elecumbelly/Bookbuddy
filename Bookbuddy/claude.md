# Bookbuddy Project Overview

**Generated:** October 27, 2025
**Last Updated:** October 31, 2025 - Version 0.5.4+

## Project Summary

**Bookbuddy** is a SwiftUI-based iOS application for personal book collection management, featuring barcode scanning, voice-enabled progress tracking, document scanner integration, and advanced photo capture with PencilKit markup and perspective correction capabilities.

## Current State - Version 0.5.4+ ✅

### Implemented Features
- ✅ **Barcode Scanner**: Camera-based ISBN scanning with real-time detection
- ✅ **Book Lookup**: Automatic metadata fetching from Open Library API
- ✅ **Voice Progress**: Hands-free reading progress updates with speech recognition
- ✅ **Document Scanner**: VNDocumentCameraViewController for page capture with automatic edge detection
- ✅ **Perspective Crop**: Optional 4-corner keystone correction with CIPerspectiveCorrection filter
- ✅ **Photo Markup**: PencilKit integration with pinch-to-zoom (up to 5x) during annotation
- ✅ **Photo Archive**: Store and view marked-up page photos with zoom capability
- ✅ **Reading Progress**: Visual progress bars and percentage tracking
- ✅ **Book Management**: Full CRUD operations with Core Data persistence
- ✅ **Audio Session Management**: Proper lifecycle handling to prevent camera/speech conflicts

### Photo Capture Flow (v0.5.4)
1. **Capture**: VNDocumentCameraViewController with automatic edge detection
2. **Preview**: 4-button interface (Adjust Crop / Markup / Share / Save to Archive)
3. **Optional Crop**: Perspective correction with draggable corner handles
4. **Optional Markup**: PencilKit annotation with zoom support
5. **Save**: Compressed JPEG storage in Core Data

## Core Technologies

- **Platform:** iOS 17.0+ (SwiftUI)
- **Data Layer:** Core Data with Book and PagePhoto entities
- **Concurrency:** Swift Concurrency (async/await)
- **Speech:** iOS Speech framework for voice input
- **Camera:** AVFoundation for barcode scanning
- **Document Scanning:** VisionKit (VNDocumentCameraViewController)
- **Image Processing:** Core Image (CIPerspectiveCorrection filter)
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
│   ├── PhotoViewerSheet.swift         # Full-screen photo viewer with zoom
│   ├── CapturedPhotoOptionsSheet.swift # Photo preview with 4-button interface
│   ├── PagePhotoCapture.swift         # Document scanner wrapper
│   └── PerspectiveCropView.swift      # Perspective correction with corner handles
├── Managers
│   ├── SpeechRecognitionManager.swift # Voice recognition engine
│   ├── BarcodeScannerView.swift       # ISBN barcode scanner
│   └── BarcodeScannerOverlay.swift    # Scanner UI overlay
├── Utilities
│   ├── ErrorAlertModifier.swift       # Reusable error alerts
│   ├── ShareSheet.swift               # iOS share functionality
│   └── IdentifiableImage.swift        # UIImage wrapper for sheets
├── Documentation
│   ├── README.md                      # User-facing documentation
│   ├── CLAUDE.md                      # This file - technical overview
│   └── .agent/                        # Agent context files
│       ├── README.md                  # Agent documentation index
│       ├── .agentmindset.md          # Development principles
│       ├── .agentsystemdata-model.md # Data model and architecture
│       └── .agentknown-issues.md     # Critical bugs and regressions
└── Assets
    └── Assets.xcassets/              # App icons, images
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
- Auto-start microphone on screen load (required for hands-free workflow)
- Recognizes "page 157", "157", or spelled numbers
- Auto-save countdown with cancellation
- Permission handling with fallback to manual entry
- **Audio Session Management**: Proper deactivation to free audio hardware for camera

### Document Scanner Integration
- **VNDocumentCameraViewController**: Apple's built-in document scanner
- Automatic edge detection and perspective correction
- Returns already-cropped scanned image
- Full-screen presentation required (`.fullScreenCover`)

### Perspective Crop
- **Optional feature**: Accessed via "Adjust Crop" button in preview
- **4-corner handles**: Draggable TL/TR/BL/BR with normalized coordinates
- **CIPerspectiveCorrection**: Core Image filter for keystone adjustment
- **Visual grid**: Rule-of-thirds overlay for alignment
- **Non-destructive**: Returns new image, doesn't modify original

### Photo Capture & Markup
- **Flow**: Scan → Preview (4 buttons) → Optional Crop → Optional Markup → Save
- **PencilKit integration**: Professional drawing tools (pen, pencil, highlighter, eraser, ruler)
- **Pinch-to-zoom**: 1x-5x during markup for precise annotations
- **Image rendering**: Max 3000px to avoid GPU memory limits
- **Scale control**: Explicit `format.scale = 1.0` to prevent 3x multiplication
- **Photo archive**: Thumbnail grid with full-screen viewer
- **Share functionality**: iOS share sheet integration

### Image Optimization
- **JPEG compression**: 70% quality for all stored images
- **Size reduction**: Typical ~500KB → ~50-100KB
- **GPU safety**: Max dimension capped at 3000px
- **External storage**: Core Data binary attributes stored externally

### Audio Session Management
- **Lifecycle control**: Activate on speech start, deactivate on stop
- **Camera compatibility**: `.notifyOthersOnDeactivation` option for audio session
- **Cleanup on disappear**: Stop speech recognition when UpdateProgressView closes
- **Proactive deactivation**: Ensure audio session inactive before opening camera

## Version History

### v0.5.4 (Current)
- Proper audio session management with `.notifyOthersOnDeactivation`
- Proactive audio session cleanup before camera access
- Fixed document scanner gesture blocking
- Comprehensive protection documentation

### v0.5.3
- Fixed gesture recognition blocking (removed haptic feedback)
- Document scanner integration improvements
- Known issues documentation

### v0.5.2
- Bug introduced: Haptic feedback blocking gestures
- Bug introduced: Aggressive audio session cleanup

### v0.5.1
- VNDocumentCameraViewController integration
- Perspective crop with 4-corner keystone correction
- Redesigned photo flow: Scan → Preview → Optional features

### v0.5.0
- Document scanner for page capture
- Initial perspective correction implementation

### v0.4
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
- iOS 17 compatibility fixes
- Accessibility improvements
- Memory management optimization

### v0.1
- Initial barcode scanner implementation
- ISBN lookup and validation
- Book CRUD operations

## Development Notes

### Testing Requirements
- **Real device required** for barcode scanning, voice recognition, and document scanner
- Simulator does not support camera or microphone
- iOS 17.0+ required for all features
- Test on devices with and without haptic support

### Permissions Required
- **Camera**: Barcode scanning, document scanning, and photo capture
- **Microphone**: Voice input for progress updates
- **Speech Recognition**: Understanding spoken page numbers

### Known Limitations
- Barcode scanning doesn't work in iOS Simulator
- Document scanner requires physical device
- Some older books may lack metadata in Open Library
- Cover images may not be available for all books

### Critical Pitfalls (see .agent/.agentknown-issues.md)
- **Never use UIImpactFeedbackGenerator** - blocks gesture recognition on devices without haptic support
- **Always deactivate audio session** when stopping speech recognition
- **Always use .fullScreenCover** for VNDocumentCameraViewController (not .sheet)
- **Don't remove auto-start speech** - required for hands-free workflow
- **Cap image rendering** at 3000px max dimension to avoid GPU limits
- **Set explicit scale = 1.0** on UIGraphicsImageRendererFormat

## Future Considerations

### Potential Enhancements
- Export library to CSV/PDF
- Reading statistics and charts
- Book recommendations based on reading history
- Notes and highlights per book
- Share book recommendations with friends
- Dark mode theming
- iPad optimization with split view
- Goodreads integration
- Book clubs and social features
- Reading goals and challenges
- Batch photo capture for multiple pages

### Technical Debt
- None significant - codebase is clean and well-organized
- Debug logging with emoji prefixes (📸 🎙️) - keep or conditionalize
- CoreData import statement consistency (minor)

## Debug Logging

The codebase includes categorized debug logging:
- **📸** - Camera/photo capture debugging (59 total occurrences across 6 files)
- **🎙️** - Speech/audio session debugging

These are intentionally kept for production debugging of complex audio/camera interactions.

## Related Documentation

- **README.md** - User-facing project documentation and usage guide
- **.agent/README.md** - AI agent context file index
- **.agent/.agentmindset.md** - Core development principles
- **.agent/.agentsystemdata-model.md** - Complete data model and architecture
- **.agent/.agentknown-issues.md** - Critical bugs and regression patterns

---

*This document is maintained as the technical overview for AI coding sessions. For user-facing documentation, see README.md.*
