import SwiftUI
import HomeUIDI
import SearchUIDI
import WishlistUIDI
import BagUIDI
import AccountUIDI
import SnackbarUIDI

struct TabScreen: View {
    @ObservedObject var navigator: Navigator
    let snackbarPresenter: SnackbarPresenter
    let homeView: AnyView
    let searchView: AnyView
    let wishlistView: AnyView
    let bagView: AnyView
    let accountView: AnyView

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
                NavigationStack(path: $navigator.accountPath) {
                    accountView
                        .navigationTitle("Account")
                        .navigationDestination(for: Destination.self) { destination in
                            destination.makeView()
                        }
                }
            }
        }
        .snackbarHost(snackbarPresenter)
    }
}
