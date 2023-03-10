//
//  SwiftUIView.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/02/22.
//

import SwiftUI
import KakaoSDKUser

struct Coupon_Page: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Coupon_Info.coupon_id, ascending: true)],
        animation: .default)
    private var couponInfo: FetchedResults<Coupon_Info>
    
    @EnvironmentObject var router: Router<Path>
    
    var body: some View {
        GeometryReader { metrics in
            TabView {
                ForEach (couponInfo) { info in
                    ZStack {
                        Image("CouponImg")
                            .resizable()
                            .frame(width: metrics.size.width * 1.2, height: metrics.size.height * 0.95)
                            .scaledToFill()
                        
                    }
                }

                Button("Logout") {
                    UserApi.shared.logout {(error) in
                        if let error = error {
                            print(error)
                        }
                        else {
                            print("logout() success.")
                            router.updateRoot(root: .Home)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                router.popToRoot()
                            }
                        }
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        
    }
}

struct Coupon_Page_Previews: PreviewProvider {
    static var previews: some View {
        Coupon_Page().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
    }
}
