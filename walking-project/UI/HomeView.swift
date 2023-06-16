//
//  HomeView.swift
//  walking-project
//
//  Created by GMC on 2023/02/22.
//

import SwiftUI
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import AuthenticationServices

struct HomeView: View {
    @State private var isLogin = false
    @EnvironmentObject var router: Router<Path>
    
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
                    if (UserApi.isKakaoTalkLoginAvailable()) {
                        UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                            if let error = error {
                                print(error)
                            }
                            else {
                                print("loginWithKakaoTalk() success.")
                                
                                router.push(.User)
                                _ = oauthToken
                            }
                        }
                    } else {
                        UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                            if let error = error {
                                print(error)
                            }
                            else {
                                print("loginWithKakaoAccount() success.\nLogging in now")
                                
                                router.push(.User)
                                _ = oauthToken
                            }
                        }
                    }
                }, label: {
                    Image("KkoLogin")
                        .resizable()
                    .scaledToFit()
                })
                .padding(.horizontal)
                .offset(y: -10)
            }
        }
        .task {
            Task{
                await HKRequestAuth()
            }
        }
    }
}

struct Home_Screen_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
