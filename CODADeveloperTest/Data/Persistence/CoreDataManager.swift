//
//  CoreDataManager.swift
//  CODADeveloperTest
//
//  Created by Dickie on 16/10/2025.
//

import CoreData

/// Manages the Core Data stack - provides persistent container and contexts
/// NOTE: Not a singleton - inject as dependency for testability
final class CoreDataManager {
    let container: NSPersistentContainer

    /// Main thread context for UI operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CODADeveloperTest")

        if inMemory {
            // Used for testing - data stored in memory only
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                // In production, handle this more gracefully
                assertionFailure("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Creates a new background context for write operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
