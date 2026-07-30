import SwiftUI
import UIKit
import Product
import SnackbarUI

public struct NotifyMeButton: View {
    private let product: Product
    private let snackbarPresenter: SnackbarPresenting

    public init(product: Product, snackbarPresenter: SnackbarPresenting) {
        self.product = product
        self.snackbarPresenter = snackbarPresenter
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            snackbarPresenter.show(Snackbar(
                title: "We'll Let You Know",
                message: "You'll hear from us when \(product.title) is back in stock.",
                icon: "bell.fill"
            ))
        } label: {
            HStack {
                Image(systemName: "bell")
                Text("Notify Me")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

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
