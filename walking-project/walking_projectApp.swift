//
//  walking_projectApp.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/01/25.
//

import SwiftUI

@main
struct walking_projectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
