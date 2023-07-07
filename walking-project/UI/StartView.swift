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
        var type : LoginType? = nil
        if let users = Auth.auth().currentUser?.providerData {
            for i in users {
                print("*********", i.providerID, "***********")
                if i.providerID == "oidc.kakao" {
                    router.setLoginType(type: .Kakao)
                    type = .Kakao
                    break
                } else if i.providerID == "apple.com" {
                    router.setLoginType(type: .Apple)
                    type = .Apple
                }
            }
        }
        return type
    }
    
    private func checkKakaoToken() {
        if (AuthApi.hasToken()) {
            UserApi.shared.accessTokenInfo { (_, error) in
                if error != nil {
                    router.updateRoot(root: .Home)
                    router.popToRoot()
                }
                else {
                    runOnlyOnceADay()
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
                runOnlyOnceADay()
                loadFeverAndCoupon()
                runOnceEveryFiveMin()
                router.updateRoot(root: .AppleMain)
                router.popToRoot()
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
            case .User : UserInfoView().navigationBarBackButtonHidden()
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
    }
}

struct Start_View_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
