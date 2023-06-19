//
//  StartßView.swift
//  walking-project
//
//  Created by GMC on 2023/03/10.
//

import SwiftUI
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKCommon

struct StartView: View {
    //Note: Scene Phase has some dumb bug when in App level and makes the router not work
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject
    var router = Router<Path>(root: .Main)

    private func checkKakaoToken() {
        if (AuthApi.hasToken()) {
            UserApi.shared.accessTokenInfo { (_, error) in
                if let error = error {
                    if let sdkError = error as? SdkError, sdkError.isInvalidTokenError() == true  {
                        router.updateRoot(root: .Home)
                        router.popToRoot()
                    }
                    else {
                        dump(error)
                    }
                }
                else {
                    loadFeverAndCoupon()
                    runOnceEveryFiveMin()
                }
            }
        }
        else {
            router.updateRoot(root: .Home)
            router.popToRoot()
        }
    }
    
    var body: some View {
        RouterView(router: router) { path in
            switch path {
            case .Home: HomeView()
            case .Main : MainView().navigationBarBackButtonHidden()
            case .User : UserInfoView()
            case .Welcome : WelcomeView()
            case .Coupon : CouponView()
            case .Settings : SettingsView()
            }
        }
        .onAppear() {
            checkKakaoToken()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                scheduleCumWalked()
            }
        }
    }
}

struct Start_View_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
