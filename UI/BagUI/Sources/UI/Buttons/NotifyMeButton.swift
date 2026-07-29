import SwiftUI
import UIKit
import Product
import SnackbarUI

/// Shown in place of Add to Bag when the shop cannot supply something but expects to
/// again. Adding it would promise a delivery nobody can make; offering to get in touch
/// is the honest version of the same intent.
///
/// Stubbed until there is a push notification system to register with — it confirms and
/// nothing else. The button exists now so the shape of the screen is settled; what it
/// does arrives with the notifications.
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

/// Shown when the shop cannot supply something and does not expect to again. There is
/// nothing to offer, so the button says so rather than pretending.
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
