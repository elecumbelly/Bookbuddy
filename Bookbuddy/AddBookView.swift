//
//  AddBookView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
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
    
    private var isbnValidationState: ISBNValidationState {
        ISBNValidator.getValidationState(isbn)
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
        NavigationView {
            Form {
                Section("Book Information") {
                    // Enhanced ISBN field with validation
                    isbnInputSection
                    
                    TextField("Title", text: $title)
                    
                    TextField("Author", text: $author)
                    
                    TextField("Page Count", text: $pageCount)
                        .keyboardType(.numberPad)
                    
                    // Publication Date with optional picker
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Publication Date")
                                .foregroundColor(.secondary)
                            if let date = publishedDate {
                                Text(date, style: .date)
                            } else {
                                Text("Not set")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(publishedDate == nil ? "Set Date" : "Change") {
                            showDatePicker = true
                        }
                        .buttonStyle(.borderless)
                        
                        if publishedDate != nil {
                            Button("Clear") {
                                publishedDate = nil
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Description") {
                    TextField("Book Description", text: $bookDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let imageData = coverImageData, let uiImage = UIImage(data: imageData) {
                    Section("Cover Preview") {
                        HStack {
                            Spacer()
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Button("Lookup ISBN") {
                        lookupBookByISBN()
                    }
                    .disabled(isbnValidationState != .valid || isLoading)
                    
                    Button("Add Book Manually") {
                        addBookManually()
                    }
                    .disabled(title.isEmpty || author.isEmpty)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addBookManually()
                    }
                    .disabled(title.isEmpty || author.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Looking up book...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
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
        }
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
        
        print("🔍 Starting ISBN lookup for: \(isbn)")
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
        print("📚 Clean ISBN: \(cleanISBN)")
        
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(cleanISBN)&format=json&jscmd=data"
        print("🌐 API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw BookLookupError.invalidURL
        }
        
        print("🚀 Starting network request...")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 HTTP Status: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200 else {
                throw BookLookupError.httpError(httpResponse.statusCode)
            }
        }
        
        print("✅ Received \(data.count) bytes of data")
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Response: \(jsonString)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BookLookupError.invalidResponse
        }
        
        print("Parsed JSON: \(json)")
        
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
        
        print("📖 All available fields: \(bookData.keys.sorted())")
        
        // Extract book information
        if let bookTitle = bookData["title"] as? String {
            title = bookTitle
            print("✅ Found title: \(bookTitle)")
        }
        
        if let authors = bookData["authors"] as? [[String: Any]],
           let firstAuthor = authors.first,
           let authorName = firstAuthor["name"] as? String {
            author = authorName
            print("✅ Found author: \(authorName)")
        }
        
        if let pages = bookData["number_of_pages"] as? Int {
            pageCount = String(pages)
            print("✅ Found page count: \(pages)")
        }
        
        // Try multiple fields for description
        if let description = bookData["notes"] as? String {
            bookDescription = description
            print("✅ Found description from notes: \(description.prefix(50))...")
        } else if let excerpts = bookData["excerpts"] as? [[String: Any]],
                  let firstExcerpt = excerpts.first,
                  let excerptText = firstExcerpt["text"] as? String {
            bookDescription = excerptText
            print("✅ Found description from excerpts: \(excerptText.prefix(50))...")
        }
        
        // Log other available fields for future use
        if let publishDate = bookData["publish_date"] as? String {
            print("📅 Available publish date: \(publishDate)")
            // Parse the publication date
            publishedDate = parsePublishDate(publishDate)
            if publishedDate != nil {
                print("✅ Parsed publication date: \(publishedDate!)")
            }
        }
        
        if let publishers = bookData["publishers"] as? [[String: Any]],
           let firstPublisher = publishers.first,
           let publisherName = firstPublisher["name"] as? String {
            print("🏢 Available publisher: \(publisherName)")
        }
        
        if let subjects = bookData["subjects"] as? [[String: Any]] {
            let subjectNames = subjects.compactMap { $0["name"] as? String }
            print("🏷️ Available subjects: \(subjectNames.prefix(3))")
        }
        
        if let cover = bookData["cover"] as? [String: Any],
           let coverUrl = cover["large"] as? String ?? cover["medium"] as? String ?? cover["small"] as? String {
            print("🖼️ Available cover image: \(coverUrl)")
            // Download the cover image
            Task {
                await downloadCoverImage(from: coverUrl)
            }
        }
    }
    
    private func addBookManually() {
        guard !title.isEmpty && !author.isEmpty else {
            showErrorMessage("Title and Author are required")
            return
        }
        
        withAnimation {
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
                showErrorMessage("Failed to save book: \(nsError.localizedDescription)")
            }
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
            print("❌ Invalid cover image URL")
            return
        }
        
        print("📥 Downloading cover image from: \(urlString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Verify it's actually image data
            if let _ = UIImage(data: data) {
                await MainActor.run {
                    coverImageData = data
                    print("✅ Cover image downloaded successfully (\(data.count) bytes)")
                }
            } else {
                print("❌ Downloaded data is not a valid image")
            }
        } catch {
            print("❌ Cover image download error: \(error.localizedDescription)")
        }
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