//
//  HomeView.swift
//  walking-project
//
//  Created by GMC on 2023/02/22.
//

import CryptoKit
import SwiftUI
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import AuthenticationServices
import FirebaseAuth

struct HomeView: View {
    @State private var isLogin = false
    @EnvironmentObject var router: Router<Path>
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func kkoLoginAction() {
        var token: OAuthToken?
        let rawNonce = randomNonceString()
        let nonce = sha256(rawNonce)
        
        Task {
            token = try? await withCheckedThrowingContinuation { continuation in
                if (UserApi.isKakaoTalkLoginAvailable()) {
                    UserApi.shared.loginWithKakaoTalk(nonce: nonce) {(oauthToken, error) in
                        if let error = error {
                            continuation.resume(throwing: error)
                        }
                        else {
                            print("loginWithKakaoTalk() success.")
                            continuation.resume(returning: oauthToken)
                        }
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount(nonce: nonce) {(oauthToken, error) in
                        if let error = error {
                            continuation.resume(throwing: error)
                        }
                        else {
                            print("loginWithKakaoAccount() success.\nLogging in now")
                            continuation.resume(returning: oauthToken)
                        }
                    }
                }
            }
            
            guard let token = token, let idToken = token.idToken else {
                UserApi.shared.logout { (error) in
                    if let error = error {
                        print(error)
                    }
                }
                return
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "oidc.kakao",  // As registered in Firebase console.
                idToken: idToken,  // ID token from OpenID Connect flow.
                rawNonce: rawNonce
            )
            
            let authResult : AuthDataResult? = try? await withCheckedThrowingContinuation { continuation in
                Auth.auth().signIn(with: credential) { authResult, error in
                    if error != nil {
                        continuation.resume(throwing: error!)
                        return
                    }
                    continuation.resume(returning: authResult)
                }
            }
            
            guard let result = authResult else {
                UserApi.shared.logout { (error) in
                    if let error = error {
                        print(error)
                    }
                }
                return
            }
            
            router.push(.User)
        }
    }
    
    var body: some View {
        ZStack (alignment: .bottom) {
            Color("MainColor").ignoresSafeArea()
            
            VStack {
                Text("Walking\nProject")
                    .font(.customFont(.home, size: 80))
                    .lineSpacing(15)
                    .multilineTextAlignment(.center)
                    .offset(y:70)
                    .foregroundColor(Color("MainTxtColor"))
                
                Image("TitleImg")
                    .resizable()
                    .scaledToFit()
                    .padding(.vertical, 60.0)
                
                Button(action: {
                    kkoLoginAction()
                }, label: {
                    Image("KkoLogin")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 20)
                })
                
                Spacer().frame(height: 20)
                
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        print("Authorisation successful")
                    case .failure(let error):
                        print("Authorisation failed: \(error.localizedDescription)")
                    }
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 60)
                .padding(.horizontal, 20)
            }
        }
        .task {
            await HKRequestAuth()
        }
    }
}

struct Home_Screen_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
