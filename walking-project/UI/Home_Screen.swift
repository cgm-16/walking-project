//
//  SwiftUIView.swift
//  walking-project
//
//  Created by GMC on 2023/02/22.
//

import SwiftUI
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser

struct Home_Screen: View {
    @State private var isLogin = false
    @EnvironmentObject var router: Router<Path>
    
    var body: some View {
        
        ZStack (alignment: .bottom) {
            Color("MainColor").ignoresSafeArea()
            
            VStack {
                Text("Walking\nProject").multilineTextAlignment(.center).font(.system(size: 70))
                    .offset(y:70)
                
                Image("TitleImg")
                    .resizable()
                    .scaledToFill()
                
                Button(action: {
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
                }, label: {
                    Image("KkoLogin")
                        .resizable()
                    .scaledToFit()
                })
                .padding(.horizontal)
                .offset(y: -30)
            }
        }
    }
}

struct Home_Screen_Previews: PreviewProvider {
    static var previews: some View {
        Home_Screen()
    }
}
