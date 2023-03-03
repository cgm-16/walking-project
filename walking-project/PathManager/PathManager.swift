//
//  PathManager.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/03/03.
//

import Foundation
import SwiftUI
@MainActor final class NavigationStore: ObservableObject {
    @Published var path = NavigationPath()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func encoded() -> Data? {
        try? path.codable.map(encoder.encode)
    }
    
    func restore(from data: Data) {
        do {
            let codable = try decoder.decode(
                NavigationPath.CodableRepresentation.self, from: data
            )
            path = NavigationPath(codable)
        } catch {
            path = NavigationPath()
        }
    }
}
