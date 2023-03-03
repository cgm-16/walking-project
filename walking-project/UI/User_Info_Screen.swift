//
//  User_Info_Screen.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/02/10.
//

import SwiftUI

struct User_Info_Screen: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Info.height, ascending: true)],
        animation: .default)
    private var myInfo: FetchedResults<My_Info>
    
    @AppStorage("Login") private var isLogin = false
    
    @State private var userName: String = ""
    @State private var isFemale: Int = -1
    @State private var userHeight: String = ""
    @State private var userWeight: String = ""
    @State private var tabselection = 1
    @State private var nextBtnDisabled: Bool = true
    @State private var isPressed = false
    @FocusState private var focusedName: Bool
    @FocusState private var focusedHeight: Bool
    
    var body: some View {
        NavigationStack {
            TabView (selection: $tabselection) {
                VStack {
                    Spacer().frame(idealHeight:100, maxHeight: 100)
                    VStack (alignment: .leading) {
                        HStack {
                            Text("Welcome\n이름을 입력해주세요")
                                .font(.system(size: 35))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                                .italic()
                            Spacer()
                        }
                        Spacer().frame(idealHeight: 100, maxHeight: 100)
                        VStack(spacing: 20.0) {
                            HStack {
                                Text("Name")
                                    .font(.system(size: 24))
                                    .fontWeight(.thin)
                                Spacer()
                            }
                            TextField("Your Name", text: $userName)
                                .font(.system(size: 35))
                                .multilineTextAlignment(.center)
                                .italic()
                                .overlay(Rectangle()
                                    .foregroundColor(/*@START_MENU_TOKEN@*/Color("MainColor")/*@END_MENU_TOKEN@*/)
                                    .offset(x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: /*@START_MENU_TOKEN@*/30.0/*@END_MENU_TOKEN@*/)
                                    .frame(height: 3))
                                .keyboardType(.namePhonePad)
                                .focused($focusedName)
                                .onChange(of: userName) {newName in
                                    let value = String(newName.replacingOccurrences(
                                        of: "\\W", with: "", options: .regularExpression).prefix(12))
                                    if value != newName {
                                        userName = value
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 35.0)
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            self.focusedName = true
                        }
                    }
                    
                    Spacer().frame(minHeight: 50, maxHeight: 500)
                    
                    Button(action: {
                        self.tabselection = 2
                    }, label: {
                        Text("Next").foregroundColor(Color.white)
                    })
                    .font(.system(size: 22))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20.0)
                    .background(Color("MainColor"))
                    .disabled(nextBtnDisabled)
                    .onChange(of: userName) { _ in
                        if userName.count == 0 {
                            nextBtnDisabled = true
                        } else {
                            nextBtnDisabled = false
                        }
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .tag(1)
                
                VStack {
                    VStack (alignment: .leading) {
                        Spacer().frame(idealHeight: 100, maxHeight: 100)
                        HStack {
                            Text("인적사항을\n입력해주세요")
                                .font(.system(size: 35))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2, reservesSpace: true)
                                .italic()
                            Spacer()
                        }
                        
                        Spacer().frame(idealHeight: 50, maxHeight: 50)
                        
                        VStack(spacing: 20.0) {
                            HStack {
                                Text("Sex")
                                    .font(.system(size: 24))
                                    .fontWeight(.thin)
                                Spacer()
                            }
                            
                            CustomSegmentedControl(preselectedIndex: $isFemale, options: ["Man", "Woman"])
                        }
                        
                        Spacer().frame(idealHeight: 80, maxHeight: 80)
                        
                        VStack(spacing: 20.0) {
                            HStack {
                                Text("Height / Weight")
                                    .font(.system(size: 24))
                                    .fontWeight(.thin)
                                Spacer()
                            }
                            HStack (alignment: .bottom) {
                                TextField("", text: $userHeight)
                                    .font(.system(size: 20))
                                    .multilineTextAlignment(.center)
                                    .italic()
                                    .frame(maxWidth: 100, maxHeight: 40)
                                    .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color("MainColor"), lineWidth: 1)
                                        )
                                    .keyboardType(.decimalPad)
                                    .focused($focusedHeight)
                                    .onAppear{
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                            self.focusedHeight = true
                                        }
                                    }
                                
                                Text ("cm").font(.system(size: 20))
                                
                                Spacer()
                                
                                TextField("", text: $userWeight)
                                    .font(.system(size: 20))
                                    .multilineTextAlignment(.center)
                                    .italic()
                                    .frame(maxWidth: 120, maxHeight: 40)
                                    .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color("MainColor"), lineWidth: 1)
                                        )
                                    .keyboardType(.decimalPad)
                                
                                Text ("kg").font(.system(size: 20))
                            }
                        }
                    }
                    .padding(.horizontal, 35.0)
                    
                    Spacer()
                    
                    Button(action: {
                        isLogin = true
                        isPressed = true
                    }, label: {
                        Text("Submit").foregroundColor(Color.white)
                        
                    })
                    .font(.system(size: 22))
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20.0)
                    .background(Color("MainColor"))
                    .disabled(nextBtnDisabled)
                    .onChange(of: userName) { _ in
                        if userName.count == 0 {
                            nextBtnDisabled = true
                        } else {
                            nextBtnDisabled = false
                        }
                    }
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeIn, value: tabselection)
            .navigationDestination(isPresented: $isPressed, destination: {Welcome_Screen()})
        }
    }
}

struct CustomSegmentedControl: View {
    @Binding var preselectedIndex: Int
    var options: [String]
    let defaultColor = Color.gray
    let selectColor = Color("MainColor")
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id:\.self) { index in
                ZStack {
                    Rectangle()
                        .fill(defaultColor.opacity(0.15))
                    Rectangle()
                        .fill(selectColor)
                        .cornerRadius(20)
                        .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2))
                        .opacity(preselectedIndex == index ? 1 : 0.01)
                        .onTapGesture {
                            withAnimation(.interactiveSpring(response: 0.2,
                                                             dampingFraction: 2,
                                                             blendDuration: 0.5)) {
                                preselectedIndex = index
                            }
                        }
                }
                .overlay(
                    Text(options[index])
                )
            }
        }
        .frame(height: 40)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("MainColor"), lineWidth: 1)
        )
    }
}

struct User_Info_Screen_Previews: PreviewProvider {
    static var previews: some View {
        User_Info_Screen()
    }
}
