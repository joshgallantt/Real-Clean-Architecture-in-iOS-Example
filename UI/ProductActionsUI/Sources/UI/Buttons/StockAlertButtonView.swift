import SwiftUI
import UIKit

/// The bell that takes the bag button's place on a card when the shop has run out but expects it
/// back. A bag it cannot fill would be a promise the shop cannot keep; this is the one it can.
public struct StockAlertButtonView: View {
    @StateObject private var viewModel: StockAlertButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> StockAlertButtonViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            Image(systemName: viewModel.isWaiting ? "bell.fill" : "bell")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(viewModel.isWaiting ? Color.yellow : .primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(viewModel.isWaiting ? "Stop telling me when this is back" : "Tell me when this is back")
    }
}

/// Taking something off the waitlist, from a card on the list itself. A minus rather than a lit
/// bell, because on a list of things a shopper is already waiting for, a bell says what is true and
/// this has to say what tapping it *does*.
///
/// It takes the bell's shape and place — a circle on the corner of a card — so the two are tapped
/// the same way and a shopper does not have to learn a second control.
public struct RemoveFromWaitlistButton: View {
    @StateObject private var viewModel: StockAlertButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> StockAlertButtonViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.didTapRemove()
        } label: {
            Image(systemName: "minus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Remove from waitlist")
    }
}

/// The same thing said at full width, where the details screen would otherwise offer Add to Bag.
public struct NotifyMeButton: View {
    @StateObject private var viewModel: StockAlertButtonViewModel

    public init(viewModel: @autoclosure @escaping () -> StockAlertButtonViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.didTap()
        } label: {
            HStack {
                Image(systemName: viewModel.isWaiting ? "bell.fill" : "bell")
                Text(viewModel.isWaiting ? "We'll Let You Know" : "Notify Me")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

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
