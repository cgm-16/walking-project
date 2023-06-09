//
//  SwiftUIView.swift
//  walking-project
//
//  Created by GMC on 2023/02/22.
//

import SwiftUI
import KakaoSDKUser
import CoreData

struct Coupon_Page: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Walk.cum_walked, ascending: true)],
        animation: .default)
    private var myWalk: FetchedResults<My_Walk>
    // TODO: Delete later
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Fever_Times.times, ascending: true)],
        animation: .default)
    private var feverTimes: FetchedResults<Fever_Times>
    // TODO: Delete later
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Coupon_Info.coupon_id, ascending: true)],
        animation: .default)
    private var couponInfo: FetchedResults<Coupon_Info>
    
    @EnvironmentObject var router: Router<Path>
    
    @State private var isVisibleConfirm: Bool = false
    @State private var isVisibleAlert: Bool = false
    
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
                            VStack (spacing: 20) {
                                Text(info.coupon_name ?? "").font(.system(size: 35))
                                if let imageURL = info.coupon_url, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .frame(width: 220, height: 220)
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
                                    let defaults = UserDefaults.standard
                                    let calendar = Calendar.current
                                    let today = calendar.startOfDay(for: Date())
                                    defaults.set(today, forKey: "lastCouponDate")
                                    router.popToRoot()
                                }
                            }
                            .alert("쿠폰을 사용할 수 없습니다.", isPresented: $isVisibleAlert) {}
                            .font(.system(size: 28))
                            .padding(20.0)
                            .frame(width: metrics.size.width * 0.5)
                            .background(Color("MainColor"))
                            .offset(y: 50)
                        }
                    }
                }
                HStack {
                    Button("Logout") {
                        UserApi.shared.logout {(error) in
                            if let error = error {
                                print(error)
                            }
                            else {
                                do {
                                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "My_Info")
                                    let objects = try viewContext.fetch(fetchRequest) as? [NSManagedObject] ?? []
                                    for object in objects {
                                        viewContext.delete(object)
                                    }
                                    try viewContext.save()
                                } catch {
                                    fatalError("Failed to save changes: \(error)")
                                }
                                print("logout() success.")
                                router.updateRoot(root: .Home)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    router.popToRoot()
                                }
                            }
                        }
                    }
                    
                    VStack {
                        ForEach(feverTimes) { info in
                            Text(info.times ?? "")
                        }
                    }
                    
                    Text(myWalk.first?.cum_walked.description ?? "yesterday no walked")
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
