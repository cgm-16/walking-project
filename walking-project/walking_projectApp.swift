//
//  walking_projectApp.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/01/25.
//

import SwiftUI

@main
struct walking_projectApp: App {
    let dataManager = DataManager.preview
    // 위쪽은 placeholder 빌드 용 아래쪽 사용할것
    // let dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            Home_Screen()
                .environment(\.managedObjectContext, dataManager.container.viewContext)
        }
    }
}
