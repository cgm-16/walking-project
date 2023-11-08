//
//  PathManager.swift
//  walking-project
//
//  Created by GMC on 2023/03/03.
//

import Foundation
import SwiftUI

@MainActor
struct RouterView<T: Hashable, Content: View>: View {
    
    @ObservedObject
    var router: Router<T>
    
    @ViewBuilder var buildView: (T) -> Content
    var body: some View {
        NavigationStack(path: $router.paths) {
            buildView(router.root)
            .navigationDestination(for: T.self) { path in
                buildView(path)
            }
        }
        .environmentObject(router)
    }
}

@MainActor
final class Router<T: Hashable>: ObservableObject {
    @Published var root: T
    @Published var paths: [T] = []
    @Published var loginAccount: LoginType?

    init(root: T) {
        self.root = root
    }

    func push(_ path: T) {
        DispatchQueue.main.async {
            self.paths.append(path)
        }
    }

    func pop() {
        DispatchQueue.main.async {
            self.paths.removeLast()
        }
    }

    func updateRoot(root: T) {
        DispatchQueue.main.async {
            self.root = root
        }
    }

    func popToRoot(){
        DispatchQueue.main.async {
            self.paths = []
        }
    }
    
    func setLoginType(type: LoginType) {
        DispatchQueue.main.async {
            self.loginAccount = type
        }
    }
}

enum Destinations {
    case Home
    case Main
    case AppleMain
    case User
    case Welcome
    case Coupon
    case Settings
}

enum LoginType {
    case Apple
    case Kakao
}
