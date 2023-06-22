//
//  StartßView.swift
//  walking-project
//
//  Created by GMC on 2023/03/10.
//

import SwiftUI
import AuthenticationServices
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKCommon
import FirebaseAuth

struct StartView: View {
    //Note: Scene Phase has some dumb bug when in App level and makes the router not work
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject
    var router = Router<Path>(root: .Main)
    
    @FetchRequest(
        entity: Login_Info.entity(),
        sortDescriptors: [],
        animation: .default)
    private var loginfo: FetchedResults<Login_Info>
    
    private func checkFirebaseLogin() -> LoginType? {
        if let users = Auth.auth().currentUser?.providerData {
            for i in users {
                if i.providerID == "oidc.kakao" {
                    router.loginAccount = .Kakao
                    break
                } else if i.providerID == "apple.com" {
                    router.loginAccount = .Apple
                }
            }
        }
        return router.loginAccount
    }
    
    private func checkKakaoToken() {
        if (AuthApi.hasToken()) {
            UserApi.shared.accessTokenInfo { (_, error) in
                if let error = error {
                    router.updateRoot(root: .Home)
                    router.popToRoot()
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
    
    private func checkAppleLogin() {
        guard let userID = loginfo.first?.appleUID else {
            router.updateRoot(root: .Home)
            router.popToRoot()
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        
        provider.getCredentialState(forUserID: userID) { credentialState, error in
            if let error = error {
                print("Error checking Apple Sign In status: \(error.localizedDescription)")
                return
            }
            
            switch credentialState {
            case .authorized:
                print("User is already signed in with Apple")
                //TODO: Make GuestView!!!
            case .revoked:
                print("User's Apple Sign In credentials have been revoked")
                router.updateRoot(root: .Home)
                router.popToRoot()
            case .notFound:
                print("User has not signed in with Apple")
                router.updateRoot(root: .Home)
                router.popToRoot()
            default:
                break
            }
        }
    }
    
    var body: some View {
        RouterView(router: router) { path in
            switch path {
            case .Home: HomeView().navigationBarBackButtonHidden()
            case .Main : MainView().navigationBarBackButtonHidden()
            case .AppleMain : MainAppleView().navigationBarBackButtonHidden()
            case .User : UserInfoView()
            case .Welcome : WelcomeView().navigationBarBackButtonHidden()
            case .Coupon : CouponView()
            case .Settings : SettingsView()
            }
        }
        .onAppear() {
            let loginType = checkFirebaseLogin()
            
            switch loginType {
            case .Kakao:
                checkKakaoToken()
            case .Apple:
                checkAppleLogin()
            case nil:
                router.updateRoot(root: .Home)
                router.popToRoot()
            }
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
