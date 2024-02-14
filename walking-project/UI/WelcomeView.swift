//
//  WelcomeScreen.swift
//  walking-project
//
//  Created by GMC on 2023/03/02.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var router: Router<Destinations>
    
    @FetchRequest(entity: My_Info.entity(), sortDescriptors: [], predicate: nil)
    private var myInfo: FetchedResults<My_Info>
    
    @State private var name : String = ""
    @State private var pronoun : String = ""
    
    var body: some View {
        VStack (spacing: 80) {
            Spacer()
            Text("Login Complete!").font(.system(size: 24, weight: .thin))
            Text("Welcome\n\(pronoun)\(name)!").font(.system(size: 43, weight: .medium))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .onAppear() {
            if let sex = myInfo.first?.isFemale {
                switch sex {
                case 0:
                    pronoun = "Mr. "
                case 1:
                    pronoun = "Ms. "
                default:
                    pronoun = ""
                }
            }
            
            name = myInfo.first?.name ?? ""
            switch router.loginAccount {
            case .Apple:
                router.updateRoot(root: .AppleMain)
            case .Kakao:
                router.updateRoot(root: .Main)
            case nil:
                router.updateRoot(root: .Main)
            }
            onAppStartRun()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                firstTimeSetup()
                runOnceEvery10Sec()
                runOnceEveryOneMin()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                router.popToRoot()
            }
        }
    }
}

struct Welcome_Screen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
