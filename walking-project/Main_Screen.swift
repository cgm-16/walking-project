//
//  ContentView.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import SwiftUI
import CoreData

// MARK: - Constants

struct Main_Screen: View {
    // MARK: - Data Fetch
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Walk_Info.score, ascending: false)],
        animation: .default)
    private var walkInfo: FetchedResults<Walk_Info>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \My_Walk.my_id, ascending: true)],
        animation: .default)
    private var myWalk: FetchedResults<My_Walk>
    
    // MARK: - Private Properties
    
    @State private var currentIndex = 0
    @State private var currentRank = 0

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack (alignment: .top) {
                // MARK: - BG Color
                GeometryReader { metrics in
                    VStack{
                        RoundedRectangle(cornerRadius: CGFloat(15), style: .circular)
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
                            VStack{
                                HStack{
                                    Spacer()
                                    
                                    if let curPoint = myWalk.first?.current_point, curPoint > 50000 {
                                        NavigationLink(destination: Coupon_Page(), label: {
                                            Image("TicketIcon")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color("AccentColor"))
                                                .imageScale(.large)
                                                .font(.title2)
                                        })
                                    } else {
                                        Button(action: {}, label: {
                                            Image("TicketIconDisabled")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color("AccentColor"))
                                                .imageScale(.large)
                                                .font(.title2)
                                        })
                                        .disabled(true)
                                    }
                                    
                                    NavigationLink(destination: Info_Screen(), label: {Image(systemName: "gearshape.fill")
                                            .foregroundColor(Color("AccentColor"))
                                            .imageScale(.large)
                                        .font(.title2)})
                                }
                                HStack{
                                    Text("Point")
                                        .font(.system(size: 35))
                                        .fontWeight(.light)
                                        .padding(.leading, 30.0)
                                    Spacer()
                                }
                                if let curPoint = myWalk.first?.current_point {
                                    Text(commaFormatter.string(for: curPoint)!)
                                        .font(.system(size: 83))
                                        .italic()
                                    Spacer()
                                } else {
                                    Text("0")
                                        .font(.system(size: 83))
                                        .italic()
                                }
                                Spacer()

                            }
                            .tag(0)
                            
                            VStack(alignment: .leading){
                                Text("Total Walk")
                                    .font(.system(size: 18))
                                    .fontWeight(.thin)
                                if let totWalk = myWalk.first?.total_walk {
                                    Text(commaFormatter.string(for: totWalk)!)
                                        .font(.system(size: 35))
                                        .fontWeight(.light)
                                } else {
                                    Text("0")
                                        .font(.system(size: 35))
                                        .fontWeight(.light)
                                }
                                Spacer()
                                Grid( alignment: .leading){
                                    GridRow{
                                        Text("Calories")
                                            .font(.system(size: 18))
                                            .fontWeight(.thin)
                                        Divider().overlay(Color("MainColor"))
                                        Text("Distance")
                                            .font(.system(size: 18))
                                            .fontWeight(.thin)
                                    }
                                    GridRow(alignment: .bottom){
                                        if let calories = myWalk.first?.calories {
                                            Text(commaFormatter.string(for: calories)!)
                                                .font(.system(size: 35))
                                                .italic()
                                        } else {
                                            Text("0")
                                                .font(.system(size: 35))
                                                .italic()
                                        }
                                        Divider().overlay(Color("MainColor"))
                                        if let dist = myWalk.first?.distance {
                                            Text(String(dist))
                                                .font(.system(size: 35))
                                                .italic()
                                        } else {
                                            Text("0.0")
                                                .font(.system(size: 35))
                                                .italic()
                                        }
                                        Text("km")
                                            .font(.system(size: 18))
                                            .italic()
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20.0)
                            .tag(1)
                        }
                        .frame(maxHeight: metrics.size.height * 0.27)
                        .padding(.horizontal)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .overlay(FancyIndexView(currentIndex: currentIndex), alignment: .top)
                        
                        
                        // MARK: - Ranking Zone
                        
                        VStack {
                            ScrollView{
                                VStack (spacing: 12) {
                                    ForEach(walkInfo) { info in
                                        if info.id != myWalk.first?.my_id! {
                                            HStack{
                                                VStack(spacing: 0){
                                                    HStack{
                                                        Text(String(info.rank))
                                                            .font(.system(size: 18))
                                                        Spacer()
                                                    }
                                                    HStack{
                                                        Spacer()
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .frame(width: 50, height: 50)
                                                            .offset(y: -8)
                                                    }
                                                }.frame(maxWidth: metrics.size.width * 0.15, maxHeight: metrics.size.height * 0.07)
                                                Spacer()
                                                Text(info.name!).frame(maxWidth: metrics.size.width * 0.2, maxHeight: metrics.size.height * 0.15)
                                                Spacer()
                                                Text(commaFormatter.string(for: info.score)!)
                                                    .font(.system(size: 28))
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(0)
                                            }
                                            .frame(maxWidth: metrics.size.width * 0.8, maxHeight: metrics.size.height * 0.1)
                                            .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10))
                                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(rankColor(rank: info.rank))
                                            )
                                        } else {
                                            HStack{
                                                VStack(spacing: 0){
                                                    HStack{
                                                        Text(String(info.rank))
                                                            .font(.system(size: 18))
                                                        Spacer()
                                                    }
                                                    HStack{
                                                        Spacer()
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .frame(width: 50, height: 50)
                                                            .offset(y: -8)
                                                    }
                                                }.frame(maxWidth: metrics.size.width * 0.15, maxHeight: metrics.size.height * 0.07)
                                                Spacer()
                                                Text("Me").frame(maxWidth: metrics.size.width * 0.2, maxHeight: metrics.size.height * 0.15)
                                                Spacer()
                                                Text(commaFormatter.string(for: info.score)!)
                                                    .font(.system(size: 28))
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(0)
                                            }
                                            .frame(maxWidth: metrics.size.width * 0.8, maxHeight: metrics.size.height * 0.1)
                                            .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10))
                                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(rankColor(rank: info.rank))
                                            )
                                            .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(Color("MainColor"), lineWidth: 1)
                                            )
                                        }
                                    }
                                }.frame(maxWidth: .infinity)
                            }
                            
                            ForEach(walkInfo) { info in
                                if info.id == myWalk.first?.my_id! {
                                    HStack{
                                        VStack(spacing: 0){
                                            HStack{
                                                Text(String(info.rank))
                                                    .font(.system(size: 18))
                                                Spacer()
                                            }
                                            HStack{
                                                Spacer()
                                                RoundedRectangle(cornerRadius: 20)
                                                    .frame(width: 50, height: 50)
                                                    .offset(y: -8)
                                            }
                                        }.frame(maxWidth: metrics.size.width * 0.15, maxHeight: metrics.size.height * 0.15)
                                        Spacer()
                                        Text("Me").frame(maxWidth: metrics.size.width * 0.2, maxHeight: metrics.size.height * 0.15)
                                        Spacer()
                                        if let myPoint = info.score, let myCur = myWalk.first?.current_point, myPoint > myCur {
                                            Text(commaFormatter.string(for: myPoint)!)
                                                .lineLimit(0)
                                                .font(.system(size: 28))
                                                .multilineTextAlignment(.trailing)
                                        } else if let myPoint = info.score, let myCur = myWalk.first?.current_point, myPoint < myCur {
                                            Text(commaFormatter.string(for: myCur)!)
                                                .lineLimit(0)
                                                .font(.system(size: 28))
                                                .multilineTextAlignment(.trailing)
                                        } else {
                                            Text("0")
                                                .lineLimit(0)
                                                .font(.system(size: 28))
                                                .multilineTextAlignment(.trailing)
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
                        .frame(maxWidth: metrics.size.width * 0.85)
                        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                        .cornerRadius(20)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)
                        )
                        .shadow(radius: 5, y: 5)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Private Functions
    
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Main_Screen().environment(\.managedObjectContext, DataManager.preview.container.viewContext)
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
