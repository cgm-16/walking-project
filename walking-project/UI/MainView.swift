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
        entity: Walk_Info.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Walk_Info.rank, ascending: true)],
        animation: .default)
    private var walkInfo: FetchedResults<Walk_Info>
    
    @FetchRequest(
        entity: My_Walk.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Walk.my_id, ascending: true)],
        animation: .default)
    private var myWalk: FetchedResults<My_Walk>
    
    @FetchRequest(
        entity: Rank_Percent.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Rank_Percent.top_percent, ascending: true)],
        animation: .default)
    private var rankPerc: FetchedResults<Rank_Percent>
    
    // MARK: - Private Properties
    @State private var currentIndex = 0
    @State private var currentRank = 0

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
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(1)
                                })
                                Button(action: {
                                    router.push(.Coupon)
                                }, label: {
                                    Image("TicketIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color("AccentColor"))
                                        .padding(1)
                                })
                                #endif
                                if let curPoint = myWalk.first?.current_point, curPoint >= COUPON_ACTIVATION_POINTS, checkCoupon() {
                                    Button(action: {router.push(.Coupon)}, label: {
                                        Image("TicketIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 45, height: 45)
                                            .padding(1)
                                    })
                                } else {
                                    Button(action: {}, label: {
                                        Image("TicketIconDisabled")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 45, height: 45)
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
                                Text("당신의 걷기 점수는 상위").fixedSize()
                                    .fixedSize()
                                    .font(.customFont(.main, size: 18))
                                    .italic()
                                    .foregroundColor(Color("MainTxtColor"))
                                Text(String(rankPerc.first?.top_percent ?? 1) + "%")
                                    .fixedSize()
                                    .font(.customFont(.main, size: 35))
                                    .italic()
                                    .foregroundColor(Color("MainTxtColor"))
                                Text("입니다")
                                    .fixedSize()
                                    .font(.customFont(.main, size: 18))
                                    .italic()
                                    .foregroundColor(Color("MainTxtColor"))
                            }
                            Spacer()
                            #if DEBUG
                            Text("평균: 533,000")
                                .fixedSize()
                                .font(.customFont(.main, size: 18))
                                .foregroundColor(Color("MainTxtColor"))
                            #endif
                            Spacer()
                        }
                        .tag(2)
                    }
                    .frame(maxHeight: metrics.size.height * 0.27)
                    .padding(.horizontal)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .overlay(FancyIndexView(currentIndex: currentIndex), alignment: .top)
                    
                    
                    // MARK: - Ranking Zone
                    
                    VStack {
                        ScrollView{
                            VStack(spacing: 12) {
                                ForEach(walkInfo) { info in
                                    if info.id != myWalk.first?.my_id {
                                        WalkInfoView(info: info, metrics: metrics, isCurrentUser: false)
                                    } else {
                                        WalkInfoView(info: info, metrics: metrics, isCurrentUser: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        ForEach(walkInfo) { info in
                            if info.id == myWalk.first?.my_id {
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
                                .frame(maxWidth: metrics.size.width * 0.8, maxHeight: metrics.size.height * 0.07)
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
                    .shadow(color: .black, radius: 1, y: 1)
                }
            }
        }
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

struct WalkInfoView: View {
    let info: Walk_Info
    let metrics: GeometryProxy
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
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
            
            Spacer().frame(width: 5)
            
            Text(isCurrentUser ? "Me" : info.name ?? "")
                .frame(maxWidth: metrics.size.width * 0.2, maxHeight: metrics.size.height * 0.15)
            
            Spacer()
            
            Text(commaFormatter.string(for: info.score) ?? "0")
                .font(.system(size: 28))
                .multilineTextAlignment(.leading)
                .lineLimit(0)
        }
        .frame(maxWidth: metrics.size.width * 0.8, maxHeight: metrics.size.height * 0.1)
        .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10))
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(rankColor(rank: info.rank)))
        .overlay(isCurrentUser ?
                 RoundedRectangle(cornerRadius: 20)
            .stroke(Color("MainColor"), lineWidth: 1) :
                    nil)
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
            ForEach(0..<2) { index in
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

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct Main_Screen_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
    }
}
