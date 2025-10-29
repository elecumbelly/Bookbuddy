//
//  Book.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import Foundation
import SwiftUI
public import CoreData

@objc(Book)
public class Book: NSManagedObject {
    
}

extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var isbn: String?
    @NSManaged public var publishedDate: Date?
    @NSManaged public var pageCount: Int32
    @NSManaged public var currentPage: Int32
    @NSManaged public var dateAdded: Date?
    @NSManaged public var coverImageData: Data?
    @NSManaged public var bookDescription: String?
    @NSManaged public var status: String? // "to-read", "reading", "completed"
    @NSManaged public var pagePhotos: NSSet?

}

extension Book : Identifiable {
    
    // Computed properties for convenience
    var displayTitle: String {
        return title ?? "Unknown Title"
    }
    
    var displayAuthor: String {
        return author ?? "Unknown Author"
    }
    
    var readingProgress: Double {
        guard pageCount > 0 else { return 0.0 }
        return Double(currentPage) / Double(pageCount)
    }
    
    var readingProgressPercentage: Int {
        return Int(readingProgress * 100)
    }
    
    var statusEnum: BookStatus {
        get {
            return BookStatus(rawValue: status ?? "to-read") ?? .toRead
        }
        set {
            status = newValue.rawValue
        }
    }

    var pagePhotosArray: [PagePhoto] {
        let set = pagePhotos as? Set<PagePhoto> ?? []
        return set.sorted {
            ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast)
        }
    }
}

// MARK: - PagePhotos Relationship Helpers
extension Book {

    @objc(addPagePhotosObject:)
    @NSManaged public func addToPagePhotos(_ value: PagePhoto)

    @objc(removePagePhotosObject:)
    @NSManaged public func removeFromPagePhotos(_ value: PagePhoto)

    @objc(addPagePhotos:)
    @NSManaged public func addToPagePhotos(_ values: NSSet)

    @objc(removePagePhotos:)
    @NSManaged public func removeFromPagePhotos(_ values: NSSet)
}

enum BookStatus: String, CaseIterable {
    case toRead = "to-read"
    case reading = "reading"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .toRead: return "To Read"
        case .reading: return "Reading"
        case .completed: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .toRead:
            return .blue
        case .reading:
            return .orange
        case .completed:
            return .green
        }
    }
}
