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
        case settings
        case button
        case tutorial
        
        var value: String {
            switch self {
            case .home:
                return "Luckiest Guy Regular"
            case .main:
                return ""
            case .coupon:
                return ""
            case .settings:
                return ""
            case .button:
                return ""
            case .tutorial:
                return "서울한강체 B"
            }
        }
    }
    
    static func customFont(_ type: Custom, size: CGFloat = 17) -> Font {
        return .custom(type.value, size: size)
    }
}
