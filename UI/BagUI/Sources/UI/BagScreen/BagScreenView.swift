import SwiftUI
import UIKit
import Kingfisher
import Product

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    @State private var isConfirmingRemoveAll = false

    /// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: a bell this
    /// screen cannot name. `Component/StockAlert` and its buttons live outside this feature, so the
    /// app layer passes one in already built and BagUI stays unaware there is a stock alert domain.
    /// The erasure is what a boundary costs, not a shortcut around one.
    ///
    /// No default. One of these used to be a wishlist button that nothing rendered, and a default
    /// `EmptyView()` is exactly why nobody noticed.
    let stockAlertButton: (ProductID) -> AnyView

    /// A way out of the bag that this screen cannot name, arriving the same way the bell does.
    /// `Component/Order` lives outside this feature, so the app layer passes a finished button in
    /// and `BagUI` stays unaware there is an order domain — which is what keeps the payment stack
    /// out of the dependency list of every screen that renders a bag row.
    let checkoutButton: AnyView

    public init(
        viewModel: BagScreenViewModel,
        stockAlertButton: @escaping (ProductID) -> AnyView,
        checkoutButton: AnyView
    ) {
        self.viewModel = viewModel
        self.stockAlertButton = stockAlertButton
        self.checkoutButton = checkoutButton
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty && !viewModel.hasNews {
                ContentUnavailableView(
                    "Your Bag is Empty",
                    systemImage: "bag",
                    description: Text("Items you add to your bag will appear here.")
                )
            } else {
                List {
                    ForEach(viewModel.noticeSections) { noticeSection($0) }
                    if !viewModel.isEmpty { bagSection }
                }
                .listStyle(.insetGrouped)
                .safeAreaInset(edge: .bottom) {
                    if !viewModel.isEmpty { totalFooter }
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $isConfirmingRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) { viewModel.didRemoveEverything() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This empties your bag. It cannot be undone.")
        }
    }
    
    // MARK: - What the shop changed

    /// Every notice section, drawn the same way. What one is called, what it says for itself and
    /// what it offers arrive as data — the view has no list of them and gains nothing when there is
    /// a sixth.
    private func noticeSection(_ section: NoticeSection) -> some View {
        Section {
            /// A section that cannot name its lines shows none. The heading has already said the
            /// whole of what is known, and rows would only repeat it once per anonymous placeholder.
            if section.listsItsRows {
                ForEach(section.rows) { row in
                    noticeRow(row, in: section)
                }
            }
        } header: {
            sectionHeader(
                section.title,
                icon: section.icon,
                tint: color(section.tint),
                description: section.description
            ) {
                Button("Okay") { viewModel.didAcceptAll(section.kind) }
            }
        }
    }

    /// The one thing about a section the view really does decide. A presenter naming `Color` would
    /// need SwiftUI, and a presenter that imports SwiftUI has started becoming a view.
    private func color(_ tint: NoticeSection.Tint) -> Color {
        switch tint {
        case .quiet: .secondary
        case .warning: .orange
        case .good: .accentColor
        }
    }

    @ViewBuilder
    private func accessoryButton(_ accessory: NoticeSection.Accessory, for id: ProductID) -> some View {
        switch accessory {
        case .nothing: EmptyView()
        case .tellMeWhenItIsBack: stockAlertButton(id)
        case .removeFromBag: removeFromBagButton(id)
        }
    }

    /// A shopper who agreed to one price and is being asked for a higher one needs a way out of it
    /// without hunting the bag for the line again. It takes the bell's shape because it stands
    /// where the bell stands and is tapped the same way — once, on the right of a row, and the row
    /// is dealt with — and a capsule reading "Remove" among circles was the odd one out.
    ///
    /// `bag.badge.minus` rather than an X. An X on a notice reads as dismissing the notice, which
    /// is what Okay above it already does, and the two are not the same: one keeps the product at
    /// the new price and the other gives it back. Red because this is the only accessory on the
    /// screen that takes something away.
    private func removeFromBagButton(_ id: ProductID) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.didRemoveChangedItem(productId: id)
        } label: {
            Image(systemName: "bag.badge.minus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Remove from bag")
    }

    /// One row for every notice, so a shopper reads them the same way wherever they appear. What a
    /// row says is only ever what its heading has not already said, and most say nothing at all —
    /// they are a picture and a name, which is what a shopper opened the section to find out.
    private func noticeRow(_ row: NoticeRow, in section: NoticeSection) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                thumbnail(url: row.imageURL)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.name ?? " ")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .redacted(reason: row.name == nil ? .placeholder : [])

                    switch row.says {
                    case .nothing:
                        EmptyView()

                    case .howManyLeft(let howMany):
                        Text(howMany)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                    case .priceMoved(let move):
                        priceMove(move)
                    }
                }

                Spacer(minLength: 0)
            }
            /// The same target as a bag line: everything left of the accessory. A shopper reading
            /// that something got dearer wants to go and look at it, and had no way to.
            .contentShape(Rectangle())
            .onTapGesture { viewModel.didTapNotice(in: section.kind, productId: row.id) }

            accessoryButton(section.accessory, for: row.id)
        }
        .padding(.vertical, 6)
    }

    /// The old amount struck through and the new one coloured, because a shopper takes in "less
    /// than it was" faster than they read it. Down is the accent colour rather than green: green
    /// against red reads as a gain or a loss, and a cheaper price is neither — it is just better.
    ///
    /// Two amounts and an arrow sit on one line until a product is expensive enough that they do
    /// not. An amount that wraps is broken mid-number and has to be reassembled to be read, which
    /// is the one thing a price may never ask of anybody. So neither amount can wrap or truncate:
    /// when the line runs out they take a second one together, in the same order, still reading
    /// old-then-new.
    private func priceMove(_ move: NoticeRow.PriceMove) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                oldAmount(move)
                direction(move)
                newAmount(move)
            }

            VStack(alignment: .leading, spacing: 2) {
                oldAmount(move)

                HStack(spacing: 6) {
                    direction(move)
                    newAmount(move)
                }
            }
        }
        .font(.subheadline)
        .monospacedDigit()
    }

    /// `fixedSize` is what makes the fallback happen. Left to itself a `Text` would rather wrap than
    /// report that it does not fit, so nothing above would ever measure as too wide.
    private func oldAmount(_ move: NoticeRow.PriceMove) -> some View {
        Text(move.was)
            .strikethrough()
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
    }

    private func direction(_ move: NoticeRow.PriceMove) -> some View {
        Image(systemName: move.isCheaper ? "arrow.down" : "arrow.up")
            .font(.caption2.weight(.bold))
            .foregroundStyle(move.isCheaper ? Color.accentColor : .orange)
    }

    private func newAmount(_ move: NoticeRow.PriceMove) -> some View {
        Text(move.now)
            .fontWeight(.semibold)
            .foregroundStyle(move.isCheaper ? Color.accentColor : .orange)
            .lineLimit(1)
            .fixedSize()
    }

    // MARK: - The bag itself

    private var bagSection: some View {
        Section {
            ForEach(viewModel.rows) { row in
                bagRow(row)
                    .swipeActions {
                        Button("Remove", role: .destructive) {
                            viewModel.didSwipeToDelete(productId: row.id)
                        }
                    }
            }
        } header: {
            sectionHeader(
                "Your Bag",
                icon: "bag",
                tint: .accentColor,
                description: "The good stuff. Swipe to drop a line, or start over."
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
    private func bagRow(_ row: BagRow) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                thumbnail(url: row.imageURL)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.name ?? " ")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .redacted(reason: row.name == nil ? .placeholder : [])

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
            .onTapGesture { viewModel.didTapRow(productId: row.id) }

            Stepper(
                value: Binding(
                    get: { row.quantity },
                    set: {
                        UISelectionFeedbackGenerator().selectionChanged()
                        viewModel.didChangeQuantity(productId: row.id, quantity: $0)
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

    /// The description sits with the heading and the action rather than under the rows, so a
    /// shopper reads what a section is and what they can do about it before they read its contents
    /// — and does not have to scroll past the rows to find out why they are there.
    private func sectionHeader<Trailing: View>(
        _ title: String,
        icon: String,
        tint: Color,
        description: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)

                Spacer()

                trailing()
                    .font(.footnote.weight(.semibold))
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func thumbnail(url: String?) -> some View {
        if let url {
            KFImage(URL(string: url))
                .resizable()
                .placeholder { ProgressView() }
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 56, height: 56)
        }
    }

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
