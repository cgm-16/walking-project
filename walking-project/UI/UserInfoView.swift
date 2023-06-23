//
//  UserInfoView.swift
//  walking-project
//
//  Created by GMC on 2023/02/10.
//

import SwiftUI
import Combine
import UIKit

struct UserInfoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(entity: My_Info.entity(), sortDescriptors: [], predicate: nil)
    private var myInfo: FetchedResults<My_Info>
    
    @EnvironmentObject var router: Router<Path>
    
    @State private var userName: String = ""
    @State private var userData = UserData(isFemale: -1, userWeight: "", userHeight: "")
    @State private var tabselection = 1
    @State private var nextBtnDisabled: Bool = true
    @State private var submitBtnDisabled: Bool = true
    @State private var isButtonPressed: Bool = false
    @State var isKeyboardPresented = false
    @State private var isPopupShown = false
    @FocusState private var focusedName: Bool
    @FocusState private var focusedHeight: Bool
    
    var body: some View {
        
        TabView (selection: $tabselection) {
            VStack {
                if !isKeyboardPresented {
                    Spacer().frame(height: 100)
                }
                
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
                
                Spacer().frame(minHeight: 0, maxHeight: 500)
                
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
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture())
            
            VStack {
                VStack (alignment: .leading) {
                    
                    if !isKeyboardPresented {
                        Spacer().frame(height: 100)
                    }
                    
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
                        
                        CustomSegmentedControl(preselectedIndex: $userData.isFemale, options: ["Man", "Woman"])
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
                            TextField("", text: $userData.userHeight)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .italic()
                                .frame(maxWidth: 100, maxHeight: 40)
                                .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color("MainColor"), lineWidth: 1)
                                    )
                                .keyboardType(.numberPad)
                                .focused($focusedHeight)
                                .onAppear{
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                        self.focusedHeight = true
                                    }
                                }
                                .onChange(of: userData.userHeight) {newValue in
                                    let value = String(newValue.replacingOccurrences(
                                        of: "[^0-9]", with: "", options: .regularExpression).prefix(3))
                                    if value == "0" {
                                        userData.userHeight = ""
                                    }
                                    if value != newValue {
                                        userData.userHeight = value
                                    }
                                }
                            
                            Text ("cm").font(.system(size: 20))
                            
                            Spacer()
                            
                            TextField("", text: $userData.userWeight)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .italic()
                                .frame(maxWidth: 120, maxHeight: 40)
                                .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color("MainColor"), lineWidth: 1)
                                    )
                                .keyboardType(.numberPad)
                                .onChange(of: userData.userWeight) {newValue in
                                    let value = String(newValue.replacingOccurrences(
                                        of: "[^0-9]", with: "", options: .regularExpression).prefix(3))
                                    if value == "0" {
                                        userData.userWeight = ""
                                    }
                                    if value != newValue {
                                        userData.userWeight = value
                                    }
                                }
                            
                            Text ("kg").font(.system(size: 20))
                        }
                    }
                }
                .padding(.horizontal, 35.0)
                
                Spacer()
                
                Button(action: {
                    isButtonPressed = true
                    saveMyInfo()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        isButtonPressed = false
                    }
                }, label: {
                    Text("Submit").foregroundColor(Color.white)
                    
                })
                .allowsHitTesting(!isButtonPressed)
                .font(.system(size: 22))
                .italic()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(20.0)
                .background(Color("MainColor"))
                .disabled(submitBtnDisabled)
                .onChange(of: userData) { _ in
                    if userData.isFemale == -1 || userData.userHeight == "" || userData.userWeight == "" {
                        submitBtnDisabled = true
                    } else {
                        submitBtnDisabled = false
                    }
                }
            }
            .tag(2)
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture())
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeIn, value: tabselection)
        .onAppear() {
            nextBtnDisabled = myInfo.isEmpty
            submitBtnDisabled = myInfo.isEmpty
            
            self.userName = self.myInfo.first?.name ?? ""
            self.userData.isFemale = Int(self.myInfo.first?.isFemale ?? -1)
            self.userData.userHeight = self.myInfo.first?.height.description ?? ""
            self.userData.userWeight = self.myInfo.first?.weight.description ?? ""
        }
        .onReceive(keyboardPublisher) { value in
            isKeyboardPresented = value
        }
        .overlay {
            ConfirmChangePopup(isShown: $isPopupShown, userName: $userName)
        }
    }
    
    private func saveMyInfo() {
        if let myInfo = self.myInfo.first {
            myInfo.name = self.userName
            myInfo.isFemale = Int16(self.userData.isFemale)
            myInfo.height = Int16(self.userData.userHeight) ?? 0
            myInfo.weight = Int16(self.userData.userWeight) ?? 0
            do {
                try self.viewContext.save()
                isPopupShown.toggle()
            } catch {
                print("Error saving myInfo: \(error.localizedDescription)")
            }
            
        } else {
            let newMyInfo = My_Info(context: viewContext)
            newMyInfo.name = self.userName
            newMyInfo.isFemale = Int16(self.userData.isFemale)
            newMyInfo.height = Int16(self.userData.userHeight) ?? 0
            newMyInfo.weight = Int16(self.userData.userWeight) ?? 0
            do {
                try self.viewContext.save()
                router.push(.Welcome)
            } catch {
                print("Error saving myInfo: \(error.localizedDescription)")
            }
        }
    }
}

struct ConfirmChangePopup: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var router: Router<Path>
    @Binding var isShown: Bool
    @Binding var userName : String
    @State private var didLogout = false
    
    var body: some View {
        if isShown {
            ZStack {
                Color("PromptBG")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(true)
                VStack (spacing: 33) {
                    Text("\(userName)님\n수정이 완료되었습니다.")
                        .font(.customFont(.settings, size: 24))
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                    
                    Button (
                        action: {
                            router.popToRoot()
                        }, label: {
                            Text("확인")
                                .font(.customFont(.settings, size: 20))
                                .frame(width: 124, height: 47)
                                .foregroundColor(.white)
                                .background(Color("MainColor"), in: RoundedRectangle(cornerRadius: 15))
                        }
                    )
                }
                .frame(width: 320, height: 260)
                .background(.white, in: RoundedRectangle(cornerRadius: 15))
            }
            .ignoresSafeArea()
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

struct UserData: Equatable {
    var isFemale: Int
    var userWeight: String
    var userHeight: String
}

extension View {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false })
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

struct User_Info_Screen_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
    }
}
