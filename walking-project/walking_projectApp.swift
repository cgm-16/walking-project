//
//  walking_projectApp.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/01/25.
//

import SwiftUI

@main
struct walking_projectApp: App {
    let persistenceController = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, DataManager.preview.container.viewContext)
        }
    }
}
