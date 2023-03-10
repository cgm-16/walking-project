//
//  walking_projectApp.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct walking_projectApp: App {
    init() {
        KakaoSDK.initSDK(appKey: "0e11e3b537767121ca1c53fa63ec72c6")
    }
    
    let dataManager = DataManager.preview
    // 위쪽은 placeholder 빌드 용 아래쪽 사용할것
    // let dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            Start_View()
                .environment(\.managedObjectContext, dataManager.container.viewContext)
                .onOpenURL(perform: { url in
                                if (AuthApi.isKakaoTalkLoginUrl(url)) {
                                    AuthController.handleOpenUrl(url: url)
                                }
                            })
        }
    }
}
