//
//  CODADeveloperTestApp.swift
//  CODADeveloperTest
//
//  Created by Dickie on 14/10/2025.
//

import SwiftUI
import CoreData

@main
struct CODADeveloperTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
