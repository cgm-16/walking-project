//
//  TutorialView.swift
//  walking-project
//
//  Created by CGM on 2/28/24.
//

import SwiftUI

struct TutorialView: View {
    @FetchRequest(entity: My_Info.entity(), sortDescriptors: [], predicate: nil)
    private var myInfo: FetchedResults<My_Info>
    
    @EnvironmentObject var router: Router<Destinations>
    
    private let imagesFront = [
        "Tutorial_2",
        "Tutorial_3",
        "Tutorial_4",
        "Tutorial_5",
        "Tutorial_6",
        "Tutorial_7",
        "Tutorial_8",
        "Tutorial_9",
        "Tutorial_10",
        "Tutorial_11",
        "Tutorial_12",
        "Tutorial_13",
        "Tutorial_14",
        "Tutorial_15",
        "Tutorial_16",
    ]
    
    private let imagesBack = [
        "Tutorial_18",
        "Tutorial_19",
    ]
    
    @State private var tabSelection = 1
    @State private var isTut1Tapped = false
    @State private var isTut18Tapped = false
    
    var body: some View {
        ZStack {
            Color("MainColor")
            
            TabView(selection: $tabSelection) {
                ZStack(alignment: .bottom) {
                    Image("Tutorial_1_bg")
                        .resizable()
                        .scaledToFill()
                    
                    VStack {
                        Image("Tutorial_1_bubble")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(0.8)
                            .overlay {
                                VStack(spacing: 10) {
                                    Text("안녕 \(myInfo.first?.name ?? "이름은여기")!")
                                        .font(.customFont(.tutorial, size: 34))
                                    Text("내가 안내해줄테니\n잘 따라와")
                                        .font(.customFont(.tutorial, size: 30))
                                        .multilineTextAlignment(.center)
                                }
                                .offset(y: -15)
                            }
                            .opacity(isTut1Tapped ? 1 : 0)
                            .animation(.bouncy, value: isTut1Tapped)
                            .offset(x: -5, y: 100)
                        
                        Image("Tutorial_1_bird")
                            .resizable()
                            .scaledToFit()
                            .offset(y: isTut1Tapped ? 0 : 500)
                            .animation(.easeOut, value: isTut1Tapped)
                    }
                }
                .onTapGesture {
                    if !isTut1Tapped {
                        isTut1Tapped = true
                    } else {
                        tabSelection = 2
                    }
                }
                .tag(1)
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture())
                
                ForEach(0..<15) { i in
                    Image(imagesFront[i])
                        .resizable()
                        .scaledToFill()
                        .tag(i+2)
                        .onTapGesture {
                            tabSelection = tabSelection+1 < 22 ? tabSelection+1 : 22
                        }
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture())
                }
                
                Image("Tutorial_17")
                    .resizable()
                    .scaledToFill()
                    .tag(17)
                    .onChange(of: tabSelection) { newValue in
                        if newValue == 17 {
                            print("triggered")
                            Task {
                                do {
                                    let finished = try await requestUNPerms()
                                    tabSelection = 18
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture())
                
                ZStack(alignment: .bottom) {
                    Image("Tutorial_1_bg")
                        .resizable()
                        .scaledToFill()
                    
                    VStack {
                        Image("Tutorial_1_bubble")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(0.8)
                            .overlay {
                                Text("어때 재밌겠지?")
                                    .font(.customFont(.tutorial, size: 34))
                                    .offset(y: -15)
                            }
                            .opacity(isTut18Tapped ? 1 : 0)
                            .animation(.bouncy, value: isTut18Tapped)
                            .offset(x: -5, y: 100)
                        
                        Image("Tutorial_1_bird")
                            .resizable()
                            .scaledToFit()
                            .offset(y: isTut18Tapped ? 0 : 500)
                            .animation(.easeOut, value: isTut18Tapped)
                    }
                }
                .onTapGesture {
                    if !isTut18Tapped {
                        isTut18Tapped = true
                    } else {
                        tabSelection = 19
                    }
                }
                .tag(18)
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture())
                
                ForEach(0..<2) { i in
                    Image(imagesBack[i])
                        .resizable()
                        .scaledToFill()
                        .tag(i+19)
                        .onTapGesture {
                            tabSelection = tabSelection+1 < 22 ? tabSelection+1 : 22
                        }
                        .contentShape(Rectangle())
                        .simultaneousGesture(DragGesture())
                }
                
                Image("Tutorial_20")
                    .resizable()
                    .scaledToFill()
                    .tag(21)
                    .onTapGesture {
                        router.popToRoot()
                    }
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture())
            }
        .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    TutorialView()
}
