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
    let homeView: AnyView
    let wishlistView: AnyView
    let cartView: AnyView

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("Home", systemImage: "house", value: Navigator.Tabs.home) {
                NavigationStack(path: $navigator.homePath) {
                    homeView
                        .navigationTitle("Home")
                        .navigationDestination(for: Destination.self) { destination in
                            destination.makeView()
                        }
                }
            }
            Tab("Wishlist", systemImage: "heart.fill", value: Navigator.Tabs.wishlist) {
                NavigationStack(path: $navigator.wishlistPath) {
                    wishlistView
                        .navigationTitle("Wishlist")
                        .navigationDestination(for: Destination.self) { destination in
                            destination.makeView()
                        }
                }
            }
            Tab("Cart", systemImage: "cart.fill", value: Navigator.Tabs.cart) {
                NavigationStack(path: $navigator.cartPath) {
                    cartView
                        .navigationTitle("Cart")
                        .navigationDestination(for: Destination.self) { destination in
                            destination.makeView()
                        }
                }
            }
        }
    }
}
