//
//  MainAppleView.swift
//  walking-project
//
//  Created by CGM on 2023/06/22.
//

import SwiftUI
import CoreData
import KakaoSDKUser
import AuthenticationServices
import FirebaseAuth

// MARK: - Constants

struct MainAppleView: View {
    // MARK: - Data Fetch
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: My_Walk.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Walk.current_point, ascending: true)],
        animation: .default)
    private var myWalk: FetchedResults<My_Walk>
    
    // MARK: - Private Properties
    @State private var currentIndex = 0
    @State private var currentRank = 0
    
    @EnvironmentObject var router: Router<Destinations>
    
    private let COUPON_ACTIVATION_POINTS = 50_0000
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // MARK: - BG Color
            GeometryReader { metrics in
                VStack{
                    RoundedRectangle(cornerRadius: CGFloat(15), style: .circular)
                        .frame(height: metrics.size.height * 0.45)
                        .foregroundColor(Color("MainColor"))
                        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.top/*@END_MENU_TOKEN@*/)
                }
            }
            
            // MARK: - Foreground
            
            GeometryReader { metrics in
                VStack {
                    // MARK: - TabView Zone
                    TabView(selection: $currentIndex.animation()) {
                        VStack{
                            Spacer()
                            
                            HStack{
                                Spacer()
#if DEBUG
                                Button(action: {
                                    resetCoupon()
                                }, label: {
                                    Image(systemName: "eraser.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(1)
                                })
                                Button(action: {
                                    router.push(.Coupon)
                                }, label: {
                                    Image("TicketIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(1)
                                })
#endif
                                if let curPoint = myWalk.first?.current_point, curPoint >= COUPON_ACTIVATION_POINTS, checkCoupon() {
                                    Button(action: {router.push(.Coupon)}, label: {
                                        Image("TicketIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 45, height: 45)
                                            .padding(1)
                                    })
                                } else {
                                    Button(action: {}, label: {
                                        Image("TicketIconDisabled")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 45, height: 45)
                                            .foregroundColor(Color("AccentColor"))
                                            .padding(1)
                                    })
                                    .disabled(true)
                                }
                                Spacer().frame(width: 10)
                                Button(action: {router.push(.Settings)}, label: {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundColor(Color("MainTxtColor"))
                                        .imageScale(.large)
                                    .font(.title2)})
                                Spacer().frame(width: 15)
                            }
                            HStack{
                                Text("Point")
                                    .font(.system(size: 35))
                                    .fontWeight(.light)
                                    .padding(.leading, 30.0)
                                    .foregroundColor(Color("MainTxtColor"))
                                Spacer()
                            }
                            Text(commaFormatter.string(for: myWalk.first?.current_point ?? 0) ?? "0")
                                .font(.system(size: 83))
                                .italic()
                                .foregroundColor(Color("MainTxtColor"))
                            Spacer()
                        }
                        .tag(0)
                        
                        VStack(alignment: .leading){
                            Spacer()
                            Text("Total Walk")
                                .font(.system(size: 18))
                                .fontWeight(.thin)
                                .foregroundColor(Color("MainTxtColor"))
                            
                            Text(commaFormatter.string(for: myWalk.first?.total_walk ?? 0) ?? "0")
                                .font(.system(size: 35))
                                .fontWeight(.light)
                                .foregroundColor(Color("MainTxtColor"))
                            Spacer()
                            Grid( alignment: .leading){
                                GridRow{
                                    Text("Calories")
                                        .font(.system(size: 18))
                                        .fontWeight(.thin)
                                        .foregroundColor(Color("MainTxtColor"))
                                    Divider().overlay(Color("MainColor"))
                                    Text("Distance")
                                        .font(.system(size: 18))
                                        .fontWeight(.thin)
                                        .foregroundColor(Color("MainTxtColor"))
                                }
                                GridRow(alignment: .bottom){
                                    Text(String(((myWalk.first?.calories ?? 0) * 10).rounded()/10))
                                        .fixedSize()
                                        .font(.customFont(.main, size: 35))
                                        .italic()
                                        .foregroundColor(Color("MainTxtColor"))
                                    
                                    Divider().overlay(Color("MainColor"))
                                    
                                    Text(String(((myWalk.first?.distance ?? 0) * 100).rounded()/100))
                                        .fixedSize()
                                        .font(.customFont(.main, size: 35))
                                        .italic()
                                        .foregroundColor(Color("MainTxtColor"))
                                    Text("km")
                                        .font(.system(size: 18))
                                        .italic()
                                        .foregroundColor(Color("MainTxtColor"))
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20.0)
                        .tag(1)
                    }
                    .frame(maxHeight: metrics.size.height * 0.27)
                    .padding(.horizontal)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .overlay(FancyIndexView(currentIndex: currentIndex), alignment: .top)
                    
                    // MARK: - Ranking Zone
                    
                    Image("LeaderBoardImg")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: metrics.size.width * 0.8)
                }
            }
            
            // MARK: - Top layer
            C2AView()
        }
    }
}

struct C2AView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var router: Router<Destinations>
    @State private var didLogout = false
    
    var body: some View {
        VStack {
            Text("리더보드 활성화를 위해\n카카오 연동을 해보세요!")
                .font(.customFont(.main, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(width: 250, height: 80, alignment: .top)
                .lineSpacing(10)
            Button (
                action: {
                    logout()
                }, label: {
                    Text("카카오로 로그인")
                        .font(.customFont(.main, size: 20))
                        .padding(.horizontal, 42)
                        .padding(.vertical, 8)
                        .frame(width: 235, height: 29, alignment: .center)
                        .background(Color(red: 0.98, green: 0.88, blue: 0))
                        .cornerRadius(15)
                }
            )
        }
        .frame(width: 360, height: 180)
        .background(Color("MainColor").opacity(0.9), in: RoundedRectangle(cornerRadius: 15))
        .offset(y: 80)
        .alert("탈퇴 완료.", isPresented: $didLogout, actions: {})
    }
    
    private func logout() {
        if router.loginAccount == .Kakao {
            UserApi.shared.unlink { (error) in
                if let error = error {
                    print(error)
                }
                else {
                    do {
                        let myInfoFetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "My_Info")
                        let myInfoObj = try viewContext.fetch(myInfoFetchReq) as? [NSManagedObject] ?? []
                        for object in myInfoObj {
                            viewContext.delete(object)
                        }
                        try viewContext.save()
                    } catch {
                        fatalError("Failed to save changes: \(error)")
                    }
                }
            }
        } else if router.loginAccount == .Apple {
            do {
                let myInfoFetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "My_Info")
                let myInfoObj = try viewContext.fetch(myInfoFetchReq) as? [NSManagedObject] ?? []
                for object in myInfoObj {
                    viewContext.delete(object)
                }
                let loginFetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Login_Info")
                let loginObj = try viewContext.fetch(loginFetchReq) as? [NSManagedObject] ?? []
                for object in loginObj {
                    viewContext.delete(object)
                }
                try viewContext.save()
            } catch {
                fatalError("Failed to save changes: \(error)")
            }
        }
        
        Auth.auth().currentUser?.delete()
        didLogout = true
        router.updateRoot(root: .Home)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            router.popToRoot()
        }
    }
}


struct MainAppleViewPreviews: PreviewProvider {
    static var previews: some View {
        MainAppleView().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
    }
}
