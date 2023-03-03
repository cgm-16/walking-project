//
//  SwiftUIView.swift
//  walking-project
//
//  Created by GMC on 2023/02/22.
//

import SwiftUI

struct Home_Screen: View {
    //@StateObject private var navigationStore = NavigationStore()
    @AppStorage("Login") private var isLogin = false
    //@SceneStorage("navigation") private var navigationData: Data?
    @State private var isAlreadyLogin = false
    @State var isLoading: Bool = true
    
    var launchScreenView: some View {
        
        ZStack(alignment: .center) {
            
            Color("MainColor")
            .edgesIgnoringSafeArea(.all)
            
            Image("TitleImg")
                .resizable()
                .scaledToFit()
        }
    }
    
    var body: some View {
        NavigationStack /*(path: $navigationStore.path)*/ {
            ZStack (alignment: .bottom) {
                Color("MainColor").ignoresSafeArea()
                
                VStack {
                    Text("Walking\nProject").multilineTextAlignment(.center).font(.system(size: 70))
                        .offset(y:70)
                    Image("TitleImg")
                        .resizable()
                        .scaledToFill()
                    NavigationLink(destination: User_Info_Screen(), label: {
                        Image("KkoLogin")
                            .resizable()
                        .scaledToFit()})
                    .padding(.horizontal)
                    .offset(y: -30)
                }
                
                if isLoading {
                    launchScreenView.transition(.identity).zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation() {
                        self.isLoading = false
                    }
                }
            }
            .navigationDestination(isPresented: $isAlreadyLogin, destination: {Main_Screen()})
        }
        .task {
            /*
             if let navigationData {
                                    navigationStore.restore(from: navigationData)
                                }
                                
                                for await _ in navigationStore.$path.values {
                                    navigationData = navigationStore.encoded()
                                }
             */
            if isLogin {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isAlreadyLogin = true
                }
            }
        }
    }
}

struct Home_Screen_Previews: PreviewProvider {
    static var previews: some View {
        Home_Screen()
    }
}
