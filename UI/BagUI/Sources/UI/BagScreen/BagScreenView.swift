import SwiftUI
import UIKit
import Kingfisher

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    let navigation: BagNavigation

    public init(viewModel: BagScreenViewModel, navigation: BagNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "Your Bag is Empty",
                    systemImage: "bag",
                    description: Text("Items you add to your bag will appear here.")
                )
            } else {
                List {
                    if !viewModel.changedRows.isEmpty {
                        changedSection
                    }

                    Section {
                        ForEach(viewModel.rows) { row in
                            self.row(for: row)
                                .swipeActions {
                                    Button("Remove", role: .destructive) {
                                        viewModel.didSwipeToDelete(itemId: row.id)
                                    }
                                }
                                .onAppear {
                                    if row.id == viewModel.rows.last?.id {
                                        viewModel.onReachEnd()
                                    }
                                }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    totalFooter
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    // MARK: - Changed

    private var changedSection: some View {
        Section {
            ForEach(viewModel.changedRows) { changed in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        thumbnail(url: changed.imageURL)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(changed.name ?? " ")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                                .redacted(reason: changed.name == nil ? .placeholder : [])
                            Text(changed.summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 12) {
                        Button("Okay") {
                            viewModel.didAcknowledgeChange(itemId: changed.id)
                        }
                        .buttonStyle(.bordered)

                        Button("Remove", role: .destructive) {
                            viewModel.didRemoveChangedItem(itemId: changed.id)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label("Changed", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .textCase(nil)
        } footer: {
            Text("These changed while you were away. Keeping them is fine — we'll confirm everything at checkout.")
        }
    }

    // MARK: - Items

    private func row(for row: BagRow) -> some View {
        HStack(spacing: 12) {
            Button {
                navigation.openProductDetails(id: row.id)
            } label: {
                HStack(spacing: 12) {
                    thumbnail(url: row.imageURL)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.name ?? " ")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .redacted(reason: row.name == nil ? .placeholder : [])
                        Text(row.lastKnownPrice, format: .currency(code: "USD"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Stepper(
                value: Binding(
                    get: { row.quantity },
                    set: {
                        UISelectionFeedbackGenerator().selectionChanged()
                        viewModel.didChangeQuantity(itemId: row.id, quantity: $0)
                    }
                ),
                in: 1...99
            ) {
                Text("\(row.quantity)")
                    .font(.subheadline.weight(.medium))
                    .frame(minWidth: 20)
            }
            .fixedSize()
        }
    }

    @ViewBuilder
    private func thumbnail(url: String?) -> some View {
        if let url {
            KFImage(URL(string: url))
                .resizable()
                .placeholder { ProgressView() }
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 56, height: 56)
        }
    }

    private var totalFooter: some View {
        HStack {
            Text("Total")
                .font(.headline)
            Spacer()
            Text(viewModel.total, format: .currency(code: "USD"))
                .font(.headline)
        }
        .padding()
        .background(.bar)
    }
}
