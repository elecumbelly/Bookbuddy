//
//  PagePhoto.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 29/10/2025.
//

import Foundation
import SwiftUI
public import CoreData

@objc(PagePhoto)
public class PagePhoto: NSManagedObject {

}

extension PagePhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PagePhoto> {
        return NSFetchRequest<PagePhoto>(entityName: "PagePhoto")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var book: Book?

}

extension PagePhoto : Identifiable {

    // Computed properties for convenience
    var displayDate: String {
        guard let date = dateAdded else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
