//
//  SettingsView.swift
//  walking-project
//
//  Created by GMC on 2023/06/16.
//

import SwiftUI
import CoreData
import AuthenticationServices
import KakaoSDKUser
import FirebaseAuth

struct SettingsView: View {
#if DEBUG
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Walk.cum_walked, ascending: true)],
        animation: .default)
    private var myWalk: FetchedResults<My_Walk>
    // TODO: Delete later
#endif
    
    @EnvironmentObject var router: Router<Destinations>
    @State private var isPromptShown = false
    var body: some View {
        VStack (spacing: 0) {
            Text("설정").font(.customFont(.settings, size: 32))
            Spacer().frame(maxHeight: 100)
            NavigationLink(value: Destinations.User) {
                Text("인적사항 수정")
                    .font(.customFont(.settings, size: 20))
                    .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
                    .padding(.leading, 35)
            }
            Divider().frame(width: 300)
            Button (
                action:
                    {
                        isPromptShown.toggle()
                    }, label: {
                        Text("계정 탈퇴")
                            .font(.customFont(.settings, size: 20))
                            .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
                            .padding(.leading, 35)
                    }
            )
#if DEBUG
            Text("Cumulative walk: " + (myWalk.first?.cum_walked.description ?? "yesterday no walked"))
            Text("Current ScoreBoard should be: " + ((myWalk.first?.cum_walked ?? 0) + (myWalk.first?.current_point ?? 0)).description)
#endif
            Spacer()
        }.overlay {
            DeleteAccPromptView(isShown: $isPromptShown.animation())
        }
    }
}

struct DeleteAccPromptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var router: Router<Destinations>
    @Binding var isShown: Bool
    @State private var didLogout = false
    
    var body: some View {
        if isShown {
            ZStack {
                Color("PromptBG")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(true)
                VStack (spacing: 33) {
                    Text("탈퇴하면 현재 계정의\n데이터가 모두 소실됩니다.\n\n정말로 탈퇴하시겠습니까?")
                        .font(.customFont(.settings, size: 22))
                    
                    HStack(spacing: 24) {
                        Button (
                            action: {
                                isShown.toggle()
                            }, label: {
                                Text("취소")
                                    .font(.customFont(.settings, size: 20))
                                    .frame(width: 124, height: 47)
                                    .background(Color("CancelButton"), in: RoundedRectangle(cornerRadius: 15))
                            }
                        )
                        
                        Button (
                            action: {
                                logout()
                            }, label: {
                                Text("확인")
                                    .font(.customFont(.settings, size: 20))
                                    .frame(width: 124, height: 47)
                                    .background(Color("DestructiveButton"), in: RoundedRectangle(cornerRadius: 15))
                            }
                        )
                    }
                }
                .frame(width: 320, height: 260)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
            .ignoresSafeArea()
            .alert("탈퇴 완료.", isPresented: $didLogout, actions: {})
        }
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

#Preview {
    SettingsView()
}
