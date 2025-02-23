//
//  RecallMateApp.swift
//  RecallMate
//
//  Created by 野村哲裕 on 2025/02/24.
//

import SwiftUI

@main
struct RecallMateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
