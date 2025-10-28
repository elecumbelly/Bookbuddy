//
//  AddBookView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
import AVFoundation
internal import CoreData

// Error types for better error handling
enum BookLookupError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noBookFound
    case invalidISBN
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid ISBN format"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .noBookFound:
            return "No book found for this ISBN"
        case .invalidISBN:
            return "Please enter a valid 10 or 13 digit ISBN"
        }
    }
}

// ISBN Validation and Formatting
struct ISBNValidator {
    static func formatISBN(_ input: String) -> String {
        let digitsOnly = input.replacingOccurrences(of: "[^0-9X]", with: "", options: .regularExpression)
        
        if digitsOnly.count == 10 {
            // Format as ISBN-10: 123-4-56-789012-3
            let formatted = digitsOnly.enumerated().map { index, char in
                switch index {
                case 1, 3, 9: return "\(char)-"
                default: return String(char)
                }
            }.joined()
            return String(formatted.dropLast()) // Remove trailing dash
        } else if digitsOnly.count == 13 {
            // Format as ISBN-13: 123-4-56-789012-3
            let formatted = digitsOnly.enumerated().map { index, char in
                switch index {
                case 3, 4, 6, 12: return "\(char)-"
                default: return String(char)
                }
            }.joined()
            return String(formatted.dropLast()) // Remove trailing dash
        }
        
        return digitsOnly
    }
    
    static func isValidISBN(_ isbn: String) -> Bool {
        let clean = isbn.replacingOccurrences(of: "[^0-9X]", with: "", options: .regularExpression)
        
        if clean.count == 10 {
            return isValidISBN10(clean)
        } else if clean.count == 13 {
            return isValidISBN13(clean)
        }
        
        return false
    }
    
    private static func isValidISBN10(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            if index == 9 && char == "X" {
                sum += 10 * (10 - index)
            } else if let digit = char.wholeNumberValue {
                sum += digit * (10 - index)
            } else {
                return false
            }
        }
        
        return sum % 11 == 0
    }
    
    private static func isValidISBN13(_ isbn: String) -> Bool {
        guard isbn.count == 13 else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            if let digit = char.wholeNumberValue {
                sum += digit * (index % 2 == 0 ? 1 : 3)
            } else {
                return false
            }
        }
        
        return sum % 10 == 0
    }
    
    static func getValidationState(_ isbn: String) -> ISBNValidationState {
        let clean = isbn.replacingOccurrences(of: "[^0-9X]", with: "", options: .regularExpression)
        
        if clean.isEmpty {
            return .empty
        } else if clean.count < 10 {
            return .incomplete
        } else if isValidISBN(isbn) {
            return .valid
        } else {
            return .invalid
        }
    }
}

enum ISBNValidationState {
    case empty
    case incomplete
    case valid
    case invalid
    
    var color: Color {
        switch self {
        case .empty, .incomplete:
            return .primary
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }
    
    var icon: String? {
        switch self {
        case .empty, .incomplete:
            return nil
        case .valid:
            return "checkmark.circle.fill"
        case .invalid:
            return "xmark.circle.fill"
        }
    }
}

// Extension to help with DateFormatter configuration
extension DateFormatter {
    func applying(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var isbn = ""
    @State private var title = ""
    @State private var author = ""
    @State private var pageCount = ""
    @State private var bookDescription = ""
    @State private var publishedDate: Date?
    @State private var showDatePicker = false
    @State private var coverImageData: Data?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isScanning = true
    @State private var cameraPermissionDenied = false
    @FocusState private var isbnFieldFocused: Bool

    private var isbnValidationState: ISBNValidationState {
        ISBNValidator.getValidationState(isbn)
    }

    private var canSaveBook: Bool {
        !title.isEmpty && !author.isEmpty && !isLoading
    }
    
    @ViewBuilder
    private var isbnInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                isbnTextField
                
                if let iconName = isbnValidationState.icon {
                    Image(systemName: iconName)
                        .foregroundColor(isbnValidationState.color)
                }
            }
            
            // Validation feedback
            if isbnValidationState == .invalid {
                Text("Invalid ISBN format")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if isbnValidationState == .valid {
                Text("Valid ISBN")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    @ViewBuilder
    private var isbnTextField: some View {
        TextField("ISBN (10 or 13 digits)", text: $isbn)
            .keyboardType(.default)
            .textInputAutocapitalization(.never)
            .focused($isbnFieldFocused)
            .onSubmit {
                handleISBNSubmit()
            }
            .submitLabel(.search)
            .onChange(of: isbn) { oldValue, newValue in
                handleISBNChange(oldValue: oldValue, newValue: newValue)
            }
            .foregroundColor(isbnValidationState.color)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Camera Scanner Section (Top 30%)
                ZStack {
                    if cameraPermissionDenied {
                        cameraPermissionDeniedView
                    } else {
                        BarcodeScannerView(scannedCode: $isbn, isScanning: $isScanning) { code in
                            // Barcode detected - ISBN auto-filled
                        }
                        .overlay(BarcodeScannerOverlay(isScanning: isScanning))
                    }
                }
                .frame(height: 250)

                Divider()

                // Form Section (Bottom 60%)
                ScrollView {
                    VStack(spacing: 0) {
                        // Book Information Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Book Information")

                            isbnInputSection
                                .padding(.horizontal)

                            TextField("Title", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            TextField("Author", text: $author)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            TextField("Page Count", text: $pageCount)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            // Publication Date
                            publicationDateSection
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemGroupedBackground))

                        Divider()

                        // Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Description")

                            TextField("Book Description", text: $bookDescription, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemGroupedBackground))

                        // Cover Preview
                        if let imageData = coverImageData, let uiImage = UIImage(data: imageData) {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("Cover Preview")

                                HStack {
                                    Spacer()
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 150)
                                        .cornerRadius(8)
                                        .accessibilityLabel("Book cover preview for \(title.isEmpty ? "untitled book" : title)")
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .systemGroupedBackground))
                        }

                        // Action Buttons
                        Divider()

                        VStack(spacing: 10) {
                            Button(action: lookupBookByISBN) {
                                Label("Lookup ISBN", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                            }
                            .background(isbnValidationState == .valid && !isLoading ? Color.blue : Color.gray)
                            .cornerRadius(10)
                            .accessibilityHint("Searches for book information using the entered ISBN")
                            .disabled(isbnValidationState != .valid || isLoading)

                            Button(action: {
                                isbnFieldFocused = true
                            }) {
                                Label("Enter ISBN Manually", systemImage: "keyboard")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                            }
                            .background(Color.orange)
                            .cornerRadius(10)
                            .accessibilityHint("Focuses the ISBN text field so you can type the ISBN manually")
                        }
                        .padding()
                        .padding(.bottom, 100)
                        .background(Color(uiColor: .systemGroupedBackground))
                    }
                }
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.regular)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addBookManually()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .disabled(!canSaveBook)
                }
            }
            .transaction { transaction in
                transaction.animation = nil
            }
            .overlay {
                if isLoading {
                    ProgressView("Looking up book...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .errorAlert(title: "Error", isPresented: $showError, message: errorMessage)
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    DatePicker("Publication Date", selection: Binding(
                        get: { publishedDate ?? Date() },
                        set: { publishedDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .navigationTitle("Publication Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showDatePicker = false
                            }
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .task {
                // Check camera permission on appear
                let status = await CameraPermissionHelper.checkPermission()
                cameraPermissionDenied = (status == .denied || status == .restricted)
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    private var publicationDateSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Publication Date")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let date = publishedDate {
                    Text(date, style: .date)
                        .font(.body)
                } else {
                    Text("Not set")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button(publishedDate == nil ? "Set Date" : "Change") {
                showDatePicker = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if publishedDate != nil {
                Button("Clear") {
                    publishedDate = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private var cameraPermissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityLabel("Camera access denied")

            Text("Camera Access Required")
                .font(.headline)

            Text("Please enable camera access in Settings to scan ISBN barcodes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    
    // MARK: - ISBN Input Helpers
    
    private func handleISBNSubmit() {
        if isbnValidationState == .valid {
            lookupBookByISBN()
        }
    }
    
    private func handleISBNChange(oldValue: String, newValue: String) {
        // Format ISBN as user types
        let formatted = ISBNValidator.formatISBN(newValue)
        if formatted != newValue {
            isbn = formatted
        }
        
        // Auto-trigger lookup for valid ISBNs
        if isbnValidationState == .valid && formatted != ISBNValidator.formatISBN(oldValue) {
            // Small delay to allow user to finish typing
            Task {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if isbn == formatted && isbnValidationState == .valid {
                    lookupBookByISBN()
                }
            }
        }
    }
    
    private func lookupBookByISBN() {
        guard isbnValidationState == .valid else {
            showErrorMessage("Please enter a valid ISBN")
            return
        }

        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await performISBNLookup()
            } catch {
                await MainActor.run {
                    isLoading = false
                    showErrorMessage("Lookup failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performISBNLookup() async throws {
        // Use Open Library API to lookup book by ISBN
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")

        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(cleanISBN)&format=json&jscmd=data"

        guard let url = URL(string: urlString) else {
            throw BookLookupError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw BookLookupError.httpError(httpResponse.statusCode)
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BookLookupError.invalidResponse
        }

        await MainActor.run {
            processBookData(json: json, cleanISBN: cleanISBN)
            isLoading = false
        }
    }
    
    @MainActor
    private func processBookData(json: [String: Any], cleanISBN: String) {
        guard let bookData = json["ISBN:\(cleanISBN)"] as? [String: Any] else {
            if json.isEmpty {
                showErrorMessage("No book found for ISBN: \(isbn)")
            } else {
                showErrorMessage("Unexpected response format from API")
            }
            return
        }
        
        // Extract book information
        if let bookTitle = bookData["title"] as? String {
            title = bookTitle
        }

        if let authors = bookData["authors"] as? [[String: Any]],
           let firstAuthor = authors.first,
           let authorName = firstAuthor["name"] as? String {
            author = authorName
        }

        if let pages = bookData["number_of_pages"] as? Int {
            pageCount = String(pages)
        }

        // Try multiple fields for description
        if let description = bookData["notes"] as? String {
            bookDescription = description
        } else if let excerpts = bookData["excerpts"] as? [[String: Any]],
                  let firstExcerpt = excerpts.first,
                  let excerptText = firstExcerpt["text"] as? String {
            bookDescription = excerptText
        }

        // Parse publication date
        if let publishDate = bookData["publish_date"] as? String {
            publishedDate = parsePublishDate(publishDate)
        }

        // Download cover image if available
        if let cover = bookData["cover"] as? [String: Any],
           let coverUrl = cover["large"] as? String ?? cover["medium"] as? String ?? cover["small"] as? String {
            Task {
                await downloadCoverImage(from: coverUrl)
            }
        }
    }
    
    private func addBookManually() {
        // Prevent double-tap
        guard !isLoading else { return }

        guard !title.isEmpty && !author.isEmpty else {
            showErrorMessage("Title and Author are required")
            return
        }

        // Set loading state to prevent double-tap
        isLoading = true

        let newBook = Book(context: viewContext)
        newBook.id = UUID()
        newBook.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newBook.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
        newBook.isbn = isbn.isEmpty ? nil : isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        newBook.bookDescription = bookDescription.isEmpty ? nil : bookDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        newBook.dateAdded = Date()
        newBook.status = BookStatus.toRead.rawValue
        newBook.currentPage = 0

        // Set publication date if available
        newBook.publishedDate = publishedDate

        // Set cover image data if available
        newBook.coverImageData = coverImageData

        if let pageCountInt = Int32(pageCount) {
            newBook.pageCount = pageCountInt
        } else {
            newBook.pageCount = 0
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            isLoading = false
            showErrorMessage("Failed to save book: \(nsError.localizedDescription)")
        }
    }
    
    private func parsePublishDate(_ dateString: String) -> Date? {
        let formatters = [
            DateFormatter().applying { $0.dateFormat = "MMMM d, yyyy" },      // "January 1, 2020"
            DateFormatter().applying { $0.dateFormat = "yyyy-MM-dd" },        // "2020-01-01"
            DateFormatter().applying { $0.dateFormat = "yyyy" },              // "2020"
            DateFormatter().applying { $0.dateFormat = "MMMM yyyy" },         // "January 2020"
            DateFormatter().applying { $0.dateFormat = "MMM d, yyyy" },       // "Jan 1, 2020"
        ]
        
        for formatter in formatters {
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func downloadCoverImage(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Verify it's actually image data and compress it
            if let image = UIImage(data: data) {
                await MainActor.run {
                    coverImageData = compressImage(image)
                }
            }
        } catch {
            // Failed to download cover image - silently continue
        }
    }

    private func compressImage(_ image: UIImage) -> Data? {
        // Compress to JPEG at 70% quality for reasonable file size
        // This typically reduces cover images from ~500KB to ~50-100KB
        return image.jpegData(compressionQuality: 0.7)
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview("Add Book View") {
    AddBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}