import SwiftUI
import UIKit
import Product
import Tracking
import TrackingUI

public struct BagScreenView: View {
    let viewModel: BagScreenViewModel
    @State private var isConfirmingRemoveAll = false
    @Environment(\.trackingContext) private var trackingContext

    /// The bell, for the changes section to put on something that sold out — see
    /// `BagChangesSection`.
    ///
    /// No default. One of these used to be a wishlist button that nothing rendered, and a default
    /// `EmptyView()` is exactly why nobody saw that it was missing.
    let stockAlertButton: (Product) -> AnyView

    /// A way out of the bag that this screen cannot name, arriving the same way the bell does.
    /// `Component/Order` lives outside this feature, so the app layer passes a finished button in
    /// and `BagUI` stays unaware there is an order domain — which is what keeps the payment stack
    /// out of the dependency list of every screen that renders a bag row.
    let checkoutButton: AnyView

    public init(
        viewModel: BagScreenViewModel,
        stockAlertButton: @escaping (Product) -> AnyView,
        checkoutButton: AnyView
    ) {
        self.viewModel = viewModel
        self.stockAlertButton = stockAlertButton
        self.checkoutButton = checkoutButton
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty && !viewModel.hasChanges {
                ContentUnavailableView(
                    "Nothing in Here Yet",
                    systemImage: "bag",
                    description: Text("Anything you add shows up here.")
                )
            } else {
                List {
                    if viewModel.hasChanges {
                        BagChangesSection(viewModel: viewModel, stockAlertButton: stockAlertButton)
                    }
                    if !viewModel.isEmpty { bagSection }
                }
                .listStyle(.insetGrouped)
                .safeAreaInset(edge: .bottom) {
                    if !viewModel.isEmpty { totalFooter }
                }
            }
        }
        .onScreenAppear { viewModel.didAppear(in: $0) }
        .task { await viewModel.onAppear() }
        .onDisappear { viewModel.didDisappear() }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $isConfirmingRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) { viewModel.didRemoveEverything(in: trackingContext) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your whole bag. No undo.")
        }
    }
    
    // MARK: - The bag itself

    private var bagSection: some View {
        Section {
            ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                TrackingContextReader { context in
                    bagRow(row, context: context)
                        .swipeActions {
                            Button("Remove", role: .destructive) {
                                viewModel.didSwipeToDelete(productId: row.id, in: context)
                            }
                        }
                }
                .onImpression { viewModel.didSee(row, in: $0) }
                .trackingPosition(index)
                .trackingList(BagTrackingPlan.bagLines)
            }
        } header: {
            BagSectionHeader(
                title: "Your Bag",
                icon: "bag",
                tint: .accentColor,
                description: "The good stuff. Swipe to lose one, or clear the lot."
            ) {
                Button("Remove All", role: .destructive) { isConfirmingRemoveAll = true }
            }
        }
    }

    /// The line opens the product, and everything left of the stepper is the line. The picture, the
    /// name, the price and the space after them are one target, so a shopper aiming at a row does
    /// not have to hit the words.
    ///
    /// `contentShape` is what makes the space count. A `Spacer` draws nothing and so is hit-tested
    /// as nothing; without a shape to stand in for it the gap between the name and the stepper — the
    /// widest part of the row on a short product name — quietly did nothing when tapped.
    ///
    /// A tap gesture rather than a `Button`. Two buttons in one `List` row are two things the row
    /// can route a tap to, and a row that also carries `swipeActions` and a `Stepper` resolves that
    /// contest in its own favour often enough that the line simply did nothing. A gesture on a
    /// shaped region does not enter the contest.
    ///
    /// The stepper stays outside it either way. Changing how many you want is not opening the
    /// product, and the two would fight over the same tap.
    private func bagRow(_ row: BagRow, context: TrackingContext) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                BagThumbnail(product: row.product)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.product?.title ?? " ")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .redacted(reason: row.product == nil ? .placeholder : [])

                    Text(row.lineTotal.formatted())
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()

                    if row.quantity > 1 {
                        Text("\(row.unitPrice.formatted()) each")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { viewModel.didTapRow(row, in: context) }

            Stepper(
                value: Binding(
                    get: { row.quantity },
                    set: {
                        UISelectionFeedbackGenerator().selectionChanged()
                        viewModel.didChangeQuantity(productId: row.id, quantity: $0, in: context)
                    }
                ),
                in: 1...99
            ) {
                Text("\(row.quantity)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(minWidth: 20)
            }
            .fixedSize()
        }
        .padding(.vertical, 4)
    }

    // MARK: -

    private var totalFooter: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.headline)
                    Text(viewModel.itemCountSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(viewModel.total?.formatted() ?? "")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }

            checkoutButton
        }
        .padding()
        .background(.bar)
    }
}
