//
//  ContentView.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/03/10.
//

import SwiftUI
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKCommon

struct Start_View: View {
    @ObservedObject
    var router = Router<Path>(root: .Home)

    var body: some View {
        RouterView(router: router) { path in
            switch path {
            case .Home: Home_Screen()
            case .Main : Main_Screen()
            case .User : User_Info_Screen()
            case .Welcome : Welcome_Screen()
            case .Coupon : Coupon_Page()
            }
        }
        .task {
            if (AuthApi.hasToken()) {
                UserApi.shared.accessTokenInfo { (_, error) in
                    if let error = error {
                        if let sdkError = error as? SdkError, sdkError.isInvalidTokenError() == true  {
                            //로그인 필요
                        }
                        else {
                            //기타 에러
                        }
                    }
                    else {
                        router.updateRoot(root: .Main)
                    }
                }
            }
            else {
                //로그인 필요
            }
        }
    }
}

enum Path {
    case Home
    case Main
    case User
    case Welcome
    case Coupon
}

struct Start_View_Previews: PreviewProvider {
    static var previews: some View {
        Start_View()
    }
}
