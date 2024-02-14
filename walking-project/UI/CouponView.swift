//
//  CouponView.swift
//  walking-project
//
//  Created by GMC on 2023/02/22.
//

import SwiftUI
import KakaoSDKUser
import CoreData

struct CouponView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Coupon_Info.coupon_id, ascending: true)],
        animation: .default)
    private var couponInfo: FetchedResults<Coupon_Info>
    
    @EnvironmentObject var router: Router<Destinations>
    
    @State private var isVisibleConfirm: Bool = false
    @State private var isVisibleAlert: Bool = false
    
    private func couponUseAction() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        defaults.set(today, forKey: "lastCouponDate")
        router.popToRoot()
    }
    
    var body: some View {
        GeometryReader { metrics in
            TabView {
                ForEach (couponInfo) { info in
                    ZStack {
                        Image("CouponImg")
                            .resizable()
                            .frame(width: metrics.size.width * 1.2, height: metrics.size.height * 0.95)
                            .scaledToFill()
                        
                        VStack {
                            VStack (spacing: metrics.size.height * 0.02) {
                                Text(info.coupon_name ?? "").font(.system(size: 35))
                                if let imageURL = info.coupon_url, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .frame(width: metrics.size.height * 0.3, height: metrics.size.height * 0.3)
                                            .scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                                Text(info.coupon_discount ?? "").font(.system(size: 35))
                            }
                            
                            
                            Button(action: {
                                if checkCoupon() {
                                    isVisibleConfirm = true
                                } else {
                                    isVisibleAlert = true
                                }
                            }, label: {
                                Text("쿠폰 사용").foregroundColor(Color.white)
                            })
                            .confirmationDialog("정말로 쿠폰을 사용하시겠습니까?", isPresented: $isVisibleConfirm, titleVisibility: .visible) {
                                Button("쿠폰 사용", role: .destructive) {
                                    couponUseAction()
                                }
                            }
                            .alert("쿠폰을 사용할 수 없습니다.", isPresented: $isVisibleAlert) {}
                            .font(.system(size: 28))
                            .padding(20.0)
                            .padding(.horizontal, 25)
                            .background(Color("MainColor"))
                            .offset(y: metrics.size.height * 0.05)
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
        CouponView().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
    }
}
