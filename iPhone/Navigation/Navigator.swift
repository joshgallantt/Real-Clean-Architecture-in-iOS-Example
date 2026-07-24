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
        case home, search, bag, wishlist, account
    }

    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var bagPath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var isPresentingLogin = false

    init() {}

    // MARK: - NavigationPath controls

    func push(_ destination: Destination, tab: Tabs?) {
        let destinationTab = tab ?? selectedTab
        if destinationTab != selectedTab {
            switch destinationTab {
            case .home: homePath = NavigationPath()
            case .search: searchPath = NavigationPath()
            case .bag: bagPath = NavigationPath()
            case .wishlist: wishlistPath = NavigationPath()
            case .account: break
            }
            selectedTab = destinationTab
        }
        switch destinationTab {
        case .home: homePath.append(destination)
        case .search: searchPath.append(destination)
        case .bag: bagPath.append(destination)
        case .wishlist: wishlistPath.append(destination)
        case .account: break
        }
    }

    func pop() {
        switch selectedTab {
        case .home: homePath.removeLast()
        case .search: searchPath.removeLast()
        case .bag: bagPath.removeLast()
        case .wishlist: wishlistPath.removeLast()
        case .account: break
        }
    }
}
