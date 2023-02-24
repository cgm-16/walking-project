//
//  SwiftUIView.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/02/22.
//

import SwiftUI

struct Coupon_Page: View {
    var body: some View {
        GeometryReader { metrics in
            TabView {
                ForEach (0..<4) { _ in
                    ZStack {
                        Image("CouponImg")
                            .resizable()
                            .frame(width: metrics.size.width * 1.2, height: metrics.size.height * 0.95)
                            .scaledToFill()
                        Text("a aaaa")
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

        }
    }
}

struct Coupon_Page_Previews: PreviewProvider {
    static var previews: some View {
        Coupon_Page()
    }
}
