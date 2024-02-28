//
//  MainView.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import SwiftUI
import CoreData

// MARK: - Constants

struct MainView: View {
    // MARK: - Data Fetch
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: My_Info.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Info.my_id, ascending: true)],
        animation: .default)
    private var myInfo: FetchedResults<My_Info>
    
    @FetchRequest(
        entity: Walk_Info.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Walk_Info.rank, ascending: true)],
        animation: .default)
    private var walkInfo: FetchedResults<Walk_Info>
    
    @FetchRequest(
        entity: My_Walk.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Walk.current_point, ascending: true)],
        animation: .default)
    private var myWalk: FetchedResults<My_Walk>
    
    @FetchRequest(
        entity: Rank_Info.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Rank_Info.top_percent, ascending: true)],
        animation: .default)
    private var rankInfo: FetchedResults<Rank_Info>
    
    // MARK: - Private Properties
    @State private var currentIndex = 0
    @State private var currentRank = 0
    @State private var emoteViewShown = false
    
    @StateObject var emojiShowerViewControllerManager = EmojiShowerViewControllerManager()
    @EnvironmentObject var router: Router<Destinations>

    private let COUPON_ACTIVATION_POINTS = 50_0000
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // MARK: - BG Color
            GeometryReader { metrics in
                VStack{
                    RoundedCorner(radius: 15, corners: [.bottomLeft, .bottomRight])
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
                        VStack(spacing: 0){
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
                                        .frame(minWidth: 30, idealWidth: 45, maxWidth: 45, minHeight: 30, idealHeight: 45, maxHeight: 45)
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(1)
                                })
                                Button(action: {
                                    router.push(.Coupon)
                                }, label: {
                                    Image("TicketIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(minWidth: 30, idealWidth: 45, maxWidth: 45, minHeight: 30, idealHeight: 45, maxHeight: 45)
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(1)
                                })
                                #endif
                                if let curPoint = myWalk.first?.current_point, curPoint >= COUPON_ACTIVATION_POINTS, checkCoupon() {
                                    Button(action: {router.push(.Coupon)}, label: {
                                        Image("TicketIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(minWidth: 30, idealWidth: 45, maxWidth: 45, minHeight: 30, idealHeight: 45, maxHeight: 45)
                                            .padding(1)
                                    })
                                } else {
                                    Button(action: {}, label: {
                                        Image("TicketIconDisabled")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(minWidth: 30, idealWidth: 45, maxWidth: 45, minHeight: 30, idealHeight: 45, maxHeight: 45)
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
                        
                        VStack(alignment: .center){
                            Spacer()
                            HStack{
                                Text("당신의 걷기 점수는 상위")
                                    .fixedSize()
                                    .font(.customFont(.main, size: 20))
                                    .italic()
                                    .foregroundColor(Color("MainTxtColor"))
                                Text(String(rankInfo.first?.top_percent ?? 1) + "%")
                                    .fixedSize()
                                    .font(.customFont(.main, size: 35))
                                    .italic()
                                    .foregroundColor(Color("MainTxtColor"))
                                Text("입니다")
                                    .fixedSize()
                                    .font(.customFont(.main, size: 20))
                                    .italic()
                                    .foregroundColor(Color("MainTxtColor"))
                            }
                            Spacer()
                            Text("평균: \(commaFormatter.string(for: rankInfo.first?.avg ?? 0) ?? "0")")
                                .fixedSize()
                                .font(.customFont(.main, size: 20))
                                .italic()
                                .foregroundColor(Color("MainTxtColor"))
                            Spacer()
                        }
                        .tag(2)
                    }
                    .frame(maxHeight: metrics.size.height * 0.25)
                    .padding(.horizontal)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .overlay(FancyIndexView(currentIndex: currentIndex), alignment: .top)
                    
                    
                    // MARK: - Ranking Zone
                    
                    VStack {
                        ScrollView{
                            VStack(spacing: 12) {
                                Text("Weekly Ranking")
                                    .fixedSize()
                                    .font(.customFont(.main, size: 20))
                                    .foregroundColor(Color("MainColor"))
                                ForEach(walkInfo) { info in
                                    if info.id != myInfo.first?.my_id {
                                        WalkInfoView(info: info, metrics: metrics, isCurrentUser: false, myId: myInfo.first?.my_id ?? "")
                                    } else {
                                        WalkInfoView(info: info, metrics: metrics, isCurrentUser: true, myId: myInfo.first?.my_id ?? "")
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        ForEach(walkInfo) { info in
                            if info.id == myInfo.first?.my_id {
                                HStack{
                                    VStack(spacing: 0){
                                        HStack{
                                            Text(String(info.rank))
                                                .font(.system(size: 18))
                                            Spacer()
                                        }
                                        HStack{
                                            Spacer()
                                            if let imageURL = info.imgURL, let url = URL(string: imageURL) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .cornerRadius(20)
                                                        .frame(width: 50, height: 50)
                                                        .offset(y: -8)
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                            } else {
                                                RoundedRectangle(cornerRadius: 20)
                                                    .frame(width: 50, height: 50)
                                                    .offset(y: -8)
                                            }
                                        }
                                    }.frame(maxWidth: metrics.size.width * 0.15, maxHeight: metrics.size.height * 0.15)
                                    Spacer().frame(width: 5)
                                    Text("Me").frame(maxWidth: metrics.size.width * 0.2, maxHeight: metrics.size.height * 0.15)
                                    Spacer()
                                    if let myCur = myWalk.first?.current_point, info.score >= myCur {
                                        Text(commaFormatter.string(for: info.score) ?? "0")
                                            .lineLimit(0)
                                            .font(.system(size: 28))
                                            .multilineTextAlignment(.leading)
                                    } else if let myCur = myWalk.first?.current_point, info.score < myCur {
                                        Text(commaFormatter.string(for: info.score) ?? "0")
                                            .lineLimit(0)
                                            .font(.system(size: 28))
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .frame(maxWidth: metrics.size.width * 0.8, maxHeight: metrics.size.height * 0.065)
                                .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10))
                                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(rankColor(rank: info.rank)))
                                .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color("MainColor"), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: metrics.size.width * 0.8)
                    .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    .cornerRadius(20)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    )
                    .compositingGroup()
                    .shadow(color: .black, radius: 1, y: 1)
                }
            }
            
            // MARK: - Effect Layer
            RainView()
                .ignoresSafeArea(.all)
                .allowsHitTesting(false)
        }
        .environmentObject(emojiShowerViewControllerManager)
    }
}

struct WalkInfoView: View {
    let info: Walk_Info
    let metrics: GeometryProxy
    let isCurrentUser: Bool
    let myId: String
    
    @State private var isReactShown = false
    @State private var dragLocation : CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text(String(info.rank))
                            .font(.system(size: 18))
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        if let imageURL = info.imgURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(20)
                                    .frame(width: 50, height: 50)
                                    .offset(y: -8)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: 50, height: 50)
                                .offset(y: -8)
                        }
                    }
                }
                .frame(maxWidth: metrics.size.width * 0.15, maxHeight: metrics.size.height * 0.07)
                
                Text(isCurrentUser ? "Me" : info.name ?? "")
                    .frame(maxWidth: metrics.size.width * 0.2, maxHeight: metrics.size.height * 0.15)
                
                Spacer()
                
                Text(commaFormatter.string(for: info.score) ?? "0")
                    .font(.system(size: 28))
                    .multilineTextAlignment(.leading)
                    .lineLimit(0)
                    .offset(x: metrics.size.width * -0.06)
            }
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(rankColor(rank: info.rank)))
            
            if !isCurrentUser {
                EmotesView(info: info, metrics: metrics, isShown: isReactShown, dragLocation: dragLocation, myId: myId)
                    .animation(.easeInOut, value: isReactShown)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                dragLocation = v.translation.width
                            }
                            .onEnded { v in
                                if !isReactShown && v.location.x <= metrics.size.width * 0.3 {
                                    isReactShown = true
                                } else if isReactShown {
                                    isReactShown = false
                                }
                                dragLocation = 0
                            }
                    )
            }
            
            if isCurrentUser {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("MainColor"), lineWidth: 1)
            }
        }
        .frame(minHeight: metrics.size.height * 0.1)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct EmotesView: View {
    let info: Walk_Info
    let metrics: GeometryProxy
    let isShown: Bool
    let dragLocation: CGFloat
    let myId: String
    
    @State private var isTapped = false
    @EnvironmentObject var emojiShowerViewControllerManager: EmojiShowerViewControllerManager
    
    var body: some View {
        HStack (alignment: .center, spacing: 10) {
            Text(isShown ? ">>" : "<<")
                .font(.system(size: 13))
            Spacer()
            Button(action: {
                isTapped = true
                sendEmote(emoteType: EmoteType.hearteyes, from: myId, to: info.id ?? "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    isTapped = false
                }
                emojiShowerViewControllerManager.emojiShowerViewController.startEmojiBubble(emoteType: .hearteyes)
            }, label: {
                Text("😍").font(.system(size: 40))
            })
            .disabled(!isShown || isTapped)
            Button(action: {
                isTapped = true
                sendEmote(emoteType: EmoteType.tauntface, from: myId, to: info.id ?? "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    isTapped = false
                }
                emojiShowerViewControllerManager.emojiShowerViewController.startEmojiBubble(emoteType: .tauntface)
            }, label: {
                Text("😜").font(.system(size: 40))
            })
            .disabled(!isShown || isTapped)
            Button(action: {
                isTapped = true
                sendEmote(emoteType: EmoteType.wowface, from: myId, to: info.id ?? "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    isTapped = false
                }
                emojiShowerViewControllerManager.emojiShowerViewController.startEmojiBubble(emoteType: .wowface)
            }, label: {
                Text("😯").font(.system(size: 40))
            })
            .disabled(!isShown || isTapped)
        }
        .frame(maxWidth: metrics.size.width * 0.55, maxHeight: metrics.size.height * 0.07)
        .padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 15))
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(reactColor(rank: info.rank)))
        .offset(x:isShown ? 0 + (dragLocation <= 0 ? 0 : dragLocation) : (metrics.size.width * 0.53) + (-dragLocation <= metrics.size.width * 0.53 ? dragLocation : -metrics.size.width * 0.53))
    }
}

struct FancyIndexView: View {
    // MARK: - Public Properties
    let currentIndex: Int
    
    // MARK: - Drawing Constants
    
    private let circleSize: CGFloat = 10
    private let circleSpacing: CGFloat = 8
    
    private let primaryColor = Color.white
    private let secondaryColor = Color.white.opacity(0.6)
    
    private let smallScale: CGFloat = 0.6
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: circleSpacing) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(currentIndex == index ? primaryColor : secondaryColor)
                    .scaleEffect(currentIndex == index ? 1 : smallScale)
                    .frame(width: circleSize, height: circleSize)
                    .transition(AnyTransition.opacity.combined(with: .scale))
                    .id(index)
            }
        }
    }
}

struct RainView: UIViewControllerRepresentable {
    typealias UIViewControllerType = EmojiShowerViewController
    @EnvironmentObject var emojiShowerViewControllerManager: EmojiShowerViewControllerManager
    
    class Coordinator {
        var parent: RainView
        
        init(_ parent: RainView) {
            self.parent = parent
        }
        
        func startEmojiBubble(emoteType: EmoteType) {
            parent.emojiShowerViewControllerManager.emojiShowerViewController.startEmojiBubble(emoteType: emoteType)
        }
    }
    
    func makeUIViewController(context: Context) -> EmojiShowerViewController {
        let viewController = emojiShowerViewControllerManager.emojiShowerViewController
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: EmojiShowerViewController, context: Context) {
        // Update the view controller if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

let commaFormatter: NumberFormatter = {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    numberFormatter.maximumFractionDigits = 0
    return numberFormatter
}()

func rankColor(rank : Int16) -> Color {
    switch(rank) {
    case 1:
        return Color("Gold")
    case 2:
        return Color("Silver")
    case 3:
        return Color("Bronze")
    default:
        return Color("Default")
    }
}

func reactColor(rank : Int16) -> Color {
    switch(rank) {
    case 1:
        return Color("GoldReact")
    case 2:
        return Color("SilverReact")
    case 3:
        return Color("BronzeReact")
    default:
        return Color("DefaultReact")
    }
}

#Preview {
    MainView().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
}
