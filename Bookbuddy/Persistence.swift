//
//  Persistence.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import Foundation
internal import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        // No sample data - start with empty state for previews
        return result
    }()

    let container: NSPersistentContainer
    private(set) var loadError: Error?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Bookbuddy")

        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Log error for debugging
                print("⚠️ Core Data error: \(error.localizedDescription)")

                // Store error for potential UI display
                self.loadError = error

                // Fallback to in-memory store so app doesn't crash
                // This allows the app to continue functioning, but data won't persist
                let inMemoryDescription = NSPersistentStoreDescription()
                inMemoryDescription.type = NSInMemoryStoreType

                self.container.persistentStoreCoordinator.addPersistentStore(
                    with: inMemoryDescription
                ) { _, fallbackError in
                    if let fallbackError = fallbackError {
                        print("⚠️ Critical: Could not create fallback store: \(fallbackError)")
                    }
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
