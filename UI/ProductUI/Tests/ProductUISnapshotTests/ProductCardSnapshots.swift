import Money
import Product
import SnapshotTesting
import SwiftUI
import Testing
@testable import ProductUI

@MainActor
@Test("A product card shows the title, the brand and the price")
func aProductCardShowsWhatIsOnOffer() {
    let card = ProductCardView(product: AProduct().build())

    assertSnapshot(of: card.frame(width: 200), as: .image(layout: .sizeThatFits))
}

@MainActor
@Test("A card for something out of stock says so on the card")
func aSoldOutCardSaysSoOnTheCard() {
    let card = ProductCardView(product: AProduct().named("Blender").soldOut().build())

    assertSnapshot(of: card.frame(width: 200), as: .image(layout: .sizeThatFits))
}
