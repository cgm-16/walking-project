//
//  FontManager.swift
//  walking-project
//
//  Created by CGM on 2023/04/21.
//

import Foundation
import SwiftUI

extension Font {
    enum Custom {
        case home
        case main
        case coupon
        case button
        
        var value: String {
            switch self {
            case .home:
                return "Luckiest Guy Regular"
            case .main:
                return ""
            case .coupon:
                return ""
            case .button:
                return ""
            }
        }
    }
    
    static func customFont(_ type: Custom, size: CGFloat = 17) -> Font {
        return .custom(type.value, size: size)
    }
}
