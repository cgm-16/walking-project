//
//  Welcome_Screen.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/03/02.
//

import SwiftUI

struct Welcome_Screen: View {
    @EnvironmentObject var router: Router<Path>
    
    @FetchRequest(entity: My_Info.entity(), sortDescriptors: [], predicate: nil)
    private var myInfo: FetchedResults<My_Info>
    
    @State private var myName : String = ""
    @State private var mySex : String = ""
    
    var body: some View {
         VStack (spacing: 80) {
             Spacer()
             Text("Login Complete!").font(.system(size: 24, weight: .thin))
             Text("Welcome\n\(mySex)\(myName)!").font(.system(size: 43, weight: .medium))
                 .multilineTextAlignment(.center)
             Spacer()
        }
         .task {
             if let sex = myInfo.first?.isFemale {
                 switch sex {
                 case 0:
                     mySex = "Mr. "
                 case 1:
                     mySex = "Ms. "
                 default:
                     mySex = ""
                 }
             }
             
             myName = myInfo.first?.name ?? ""
             
             router.updateRoot(root: .Main)
             firstTimeSetup()
             DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                 scoreSync()
             }
             
             DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                 router.popToRoot()
             }
         }
    }
}

struct Welcome_Screen_Previews: PreviewProvider {
    static var previews: some View {
        Welcome_Screen()
    }
}
