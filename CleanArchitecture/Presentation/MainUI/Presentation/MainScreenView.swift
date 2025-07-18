//
//  MainScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

import SwiftUI

struct MainScreenView<Home: View, Favorites: View, Cart: View>: View {
    @ObservedObject var navigator: AppNavigator
    let homeView: () -> Home
    let favoritesView: () -> Favorites
    let cartView: () -> Cart

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("Home", systemImage: "house", value: AppNavigator.Tabs.home) {
                NavigationStack(path: $navigator.homePath) {
                    homeView()
                        .navigationTitle("Home")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }

            Tab("Favorites", systemImage: "star", value: AppNavigator.Tabs.favorites) {
                NavigationStack(path: $navigator.favoritesPath) {
                    favoritesView()
                        .navigationTitle("Favorites")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }

            Tab("Cart", systemImage: "cart.fill", value: AppNavigator.Tabs.cart) {
                NavigationStack(path: $navigator.cartPath) {
                    cartView()
                        .navigationTitle("Cart")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
        }
    }
}
