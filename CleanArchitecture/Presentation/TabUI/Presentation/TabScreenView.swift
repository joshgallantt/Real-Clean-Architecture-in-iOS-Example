//
//  TabScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

struct TabScreenView<Home: View, Wishlist: View, Cart: View>: View {
    @ObservedObject var navigator: AppNavigator
    let homeView: () -> Home
    let wishlistView: () -> Wishlist
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

            Tab("Wishlist", systemImage: "star", value: AppNavigator.Tabs.wishlist) {
                NavigationStack(path: $navigator.wishlistPath) {
                    wishlistView()
                        .navigationTitle("Wishlist")
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
