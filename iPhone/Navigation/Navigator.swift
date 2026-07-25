//
//  Navigator.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//


import SwiftUI
import Combine
import Foundation
import LoginUI

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

    private let authPresenting: AuthSheetCoordinator

    init(authPresenting: AuthSheetCoordinator) {
        self.authPresenting = authPresenting
    }

    // MARK: - Single entry point for all navigation (taps, deep links)

    /// Navigates to `destination`, first routing through the auth gate when the
    /// destination declares `requiresAuthentication`.
    func open(_ destination: Destination, tab: Tabs? = nil) {
        if destination.requiresAuthentication {
            Task { [weak self] in
                guard let self, await self.authPresenting.requireAuthentication() else { return }
                self.push(destination, tab: tab)
            }
        } else {
            push(destination, tab: tab)
        }
    }

    func pop() {
        switch selectedTab {
        case .home: if !homePath.isEmpty { homePath.removeLast() }
        case .search: if !searchPath.isEmpty { searchPath.removeLast() }
        case .bag: if !bagPath.isEmpty { bagPath.removeLast() }
        case .wishlist: if !wishlistPath.isEmpty { wishlistPath.removeLast() }
        case .account: break
        }
    }

    // MARK: - NavigationPath controls

    private func push(_ destination: Destination, tab: Tabs?) {
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
}
