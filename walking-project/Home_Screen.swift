//
//  SwiftUIView.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/02/22.
//

import SwiftUI

struct Home_Screen: View {
    
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
        NavigationStack {
            ZStack (alignment: .bottom) {
                Color("MainColor").ignoresSafeArea()
                
                VStack {
                    Text("Walking\nProject").multilineTextAlignment(.center).font(.system(size: 70))
                        .offset(y:70)
                    Image("TitleImg")
                        .resizable()
                        .scaledToFill()
                    NavigationLink(destination: Main_Screen(), label: {
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
        }
    }
}

struct Home_Screen_Previews: PreviewProvider {
    static var previews: some View {
        Home_Screen()
    }
}
