//
//  Welcome_Screen.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/03/02.
//

import SwiftUI

struct Welcome_Screen: View {
    @State private var isTransition = false
    
    var body: some View {
        NavigationStack {
             VStack (spacing: 80) {
                 Spacer()
                 Text("Login Complete!").font(.system(size: 24, weight: .thin))
                 Text("Welcome\nMr. junon!").font(.system(size: 43, weight: .medium))
                     .multilineTextAlignment(.center)
                 Spacer()
            }
             .task {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                     isTransition = true
                 }
             }
             .navigationDestination(isPresented: $isTransition, destination: {Main_Screen()})
        }
        
    }
}

struct Welcome_Screen_Previews: PreviewProvider {
    static var previews: some View {
        Welcome_Screen()
    }
}
