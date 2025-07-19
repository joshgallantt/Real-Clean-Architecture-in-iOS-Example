//
//  NavigationScreen.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 19/07/2025.
//

import SwiftUI

struct NavigationScreen<Home: View, Wishlist: View, Cart: View>: View {
    @ObservedObject var navigator: Navigation
    let homeView: Home
    let wishlistView: Wishlist
    let cartView: Cart

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("Home", systemImage: "house", value: Navigation.Tabs.home) {
                NavigationStack(path: $navigator.homePath) {
                    homeView
                        .navigationTitle("Home")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
            Tab("Wishlist", systemImage: "heart.fill", value: Navigation.Tabs.wishlist) {
                NavigationStack(path: $navigator.wishlistPath) {
                    wishlistView
                        .navigationTitle("Wishlist")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
            Tab("Cart", systemImage: "cart.fill", value: Navigation.Tabs.cart) {
                NavigationStack(path: $navigator.cartPath) {
                    cartView
                        .navigationTitle("Cart")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
        }
    }
}
