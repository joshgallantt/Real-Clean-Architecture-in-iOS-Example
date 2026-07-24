//
//  TabScreen.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 22/12/2025.
//

import SwiftUI
import HomeUIDI
import SearchUIDI
import WishlistUIDI
import BagUIDI
import AccountUIDI

struct TabScreen: View {
    @ObservedObject var navigator: Navigator
    let homeView: AnyView
    let searchView: AnyView
    let wishlistView: AnyView
    let bagView: AnyView
    let accountView: AnyView
    let loginView: AnyView

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
            Tab("Search", systemImage: "magnifyingglass", value: Navigator.Tabs.search) {
                NavigationStack(path: $navigator.searchPath) {
                    searchView
                        .navigationTitle("Search")
                        .navigationDestination(for: Destination.self) { destination in
                            destination.makeView()
                        }
                }
            }
            Tab("Bag", systemImage: "bag.fill", value: Navigator.Tabs.bag) {
                NavigationStack(path: $navigator.bagPath) {
                    bagView
                        .navigationTitle("Bag")
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
            Tab("Account", systemImage: "person.crop.circle", value: Navigator.Tabs.account) {
                NavigationStack {
                    accountView
                        .navigationTitle("Account")
                }
            }
        }
        .sheet(isPresented: $navigator.isPresentingLogin) {
            loginView
        }
    }
}
