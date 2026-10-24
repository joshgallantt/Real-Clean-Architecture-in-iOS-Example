import SwiftUI
import UIKit

/// Nothing the shop has stopped selling reaches a card or a details screen — `BrowseCatalogUseCase`
/// does not return them and `ViewProductUseCase` calls them not found — so this is what a bag left
/// over from before it went is told, and nothing else.
public struct UnavailableButton: View {
    public init() {}

    public var body: some View {
        Label("No Longer Available", systemImage: "xmark.circle")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.secondary)
    }
}
