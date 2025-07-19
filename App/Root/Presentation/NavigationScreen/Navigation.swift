//
//  Navigation.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 15/07/2025.
//


import SwiftUI
import Combine


final class Navigation: ObservableObject {
    enum Tabs: Hashable {
        case home, wishlist, cart
    }
    
    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var cartPath = NavigationPath()
    @Published var searchPath = NavigationPath()

    // Type-erased factory registry
    private var factories: [ObjectIdentifier: (Any) -> AnyView] = [:]

    // MARK: - Register a Destination
    public func register<Route: Hashable>(
        factory: @escaping (Route) -> some View
    ) {
        let key = ObjectIdentifier(Route.self)
        factories[key] = { any in
            guard let route = any as? Route else { return AnyView(EmptyView()) }
            return AnyView(factory(route))
        }
    }

    // MARK: - Lookup a Destinations
    func view(for route: Any) -> AnyView? {
        let key = ObjectIdentifier(type(of: route))
        return factories[key]?(route)
    }

    // MARK: - NavigationPath controls
    
    func resetPath(for tab: Tabs) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .wishlist: wishlistPath = NavigationPath()
        case .cart: cartPath = NavigationPath()
        }
    }

    func push(_ route: any Hashable, tab: Tabs? = nil) {
        let destinationTab = tab ?? selectedTab
        if destinationTab != selectedTab {
            resetPath(for: destinationTab)
            selectedTab = destinationTab
        }
        let anyRoute = AnyHashable(route)
        switch destinationTab {
        case .home: homePath.append(anyRoute)
        case .wishlist: wishlistPath.append(anyRoute)
        case .cart: cartPath.append(anyRoute)
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
