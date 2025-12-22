//
//  TabScreen.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 22/12/2025.
//

import SwiftUI
import HomeUIDI
import WishlistUIDI
import CartUIDI

struct TabScreen: View {
    @ObservedObject var navigator: Navigator
    
    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("Home", systemImage: "house", value: Navigator.Tabs.home) {
                NavigationStack(path: $navigator.homePath) {
                    Injector.shared.homeUIDI.mainView()
                        .navigationTitle("Home")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
            Tab("Wishlist", systemImage: "heart.fill", value: Navigator.Tabs.wishlist) {
                NavigationStack(path: $navigator.wishlistPath) {
                    Injector.shared.wishlistUIDI.mainView()
                        .navigationTitle("Wishlist")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
            Tab("Cart", systemImage: "cart.fill", value: Navigator.Tabs.cart) {
                NavigationStack(path: $navigator.cartPath) {
                    Injector.shared.cartUIDI.mainView()
                        .navigationTitle("Cart")
                        .navigationDestination(for: AnyHashable.self) { route in
                            navigator.view(for: route.base) ?? AnyView(EmptyView())
                        }
                }
            }
        }
    }
}
