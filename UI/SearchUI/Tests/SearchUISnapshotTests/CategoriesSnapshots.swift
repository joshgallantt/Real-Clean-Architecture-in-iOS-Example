import Product
import SnapshotTesting
import SwiftUI
import Testing
@testable import SearchUI

@MainActor
@Test("The categories list offers every category, and a way to see everything")
func theCategoriesListOffersEveryCategory() {
    let categories = CategoriesView(
        categories: [
            ProductCategory(id: CategoryID(rawValue: "home"), name: "Home"),
            ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty"),
            ProductCategory(id: CategoryID(rawValue: "outdoors"), name: "Outdoors")
        ],
        onSelectAll: {},
        onSelect: { _ in }
    )

    assertSnapshot(of: categories, as: .image(layout: .device(config: .iPhone13)))
}

@MainActor
@Test("A shop with nothing in it still renders, rather than collapsing to nothing")
func anEmptyCategoriesListStillRenders() {
    let categories = CategoriesView(categories: [], onSelectAll: {}, onSelect: { _ in })

    assertSnapshot(of: categories, as: .image(layout: .device(config: .iPhone13)))
}
