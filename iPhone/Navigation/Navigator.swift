import SwiftUI
import Combine
import Foundation
import AuthUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: conforms to every
/// feature's navigation protocol, so the features depend on their own declarations and never on
/// this.
final class Navigator: ObservableObject {
    enum Tabs: Hashable {
        case home, search, bag, wishlist, account
    }

    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var bagPath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var accountPath = NavigationPath()

    private let authPresenter: AuthPresenting

    init(authPresenter: AuthPresenting) {
        self.authPresenter = authPresenter
    }

    // MARK: - Single entry point for all navigation (taps, deep links)

    func open(_ destination: Destination, tab: Tabs? = nil) {
        if destination.requiresAuthentication {
            Task { [weak self] in
                guard let self, await self.authPresenter.show(.default) else { return }
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
        case .account: if !accountPath.isEmpty { accountPath.removeLast() }
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
            case .account: accountPath = NavigationPath()
            }
            selectedTab = destinationTab
        }
        switch destinationTab {
        case .home: homePath.append(destination)
        case .search: searchPath.append(destination)
        case .bag: bagPath.append(destination)
        case .wishlist: wishlistPath.append(destination)
        case .account: accountPath.append(destination)
        }
    }
}
