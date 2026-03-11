//
//  Navigator.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//


import SwiftUI
import Combine
import Foundation

@MainActor
final class Navigator: ObservableObject {
    enum Tabs: Hashable {
        case home, wishlist, cart
    }
    
    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var cartPath = NavigationPath()

    init() {}

    // MARK: - NavigationPath controls

    func push(_ destination: Destination, tab: Tabs? = nil) {
        let destinationTab = tab ?? selectedTab
        if destinationTab != selectedTab {
            switch destinationTab {
            case .home: homePath = NavigationPath()
            case .wishlist: wishlistPath = NavigationPath()
            case .cart: cartPath = NavigationPath()
            }
            selectedTab = destinationTab
        }
        switch destinationTab {
        case .home: homePath.append(destination)
        case .wishlist: wishlistPath.append(destination)
        case .cart: cartPath.append(destination)
        }
    }

    func pop() {
        switch selectedTab {
        case .home: homePath.removeLast()
        case .wishlist: wishlistPath.removeLast()
        case .cart: cartPath.removeLast()
        }
    }
}
