//
//  walking_projectApp.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import SwiftUI
import BackgroundTasks
import KakaoSDKCommon
import KakaoSDKAuth
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}


@main
struct walking_projectApp: App {
    init() {
        KakaoSDK.initSDK(appKey: "0e11e3b537767121ca1c53fa63ec72c6")
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            StartView()
                .environment(\.managedObjectContext, dataManager.container.viewContext)
                .onOpenURL(perform: { url in
                                if (AuthApi.isKakaoTalkLoginUrl(url)) {
                                    AuthController.handleOpenUrl(url: url)
                                }
                            })
        }
        .backgroundTask(.appRefresh("calc_cum")) {
            await calcCum()
        }
    }
}
