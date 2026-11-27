import SwiftUI
import Tracking

/// The view side of tracking: declaring where a view is, and saying when it appeared or was seen.
/// None of these report anything themselves — each hands a `TrackingContext` to a closure, and the
/// closure calls the view model, where what to report is decided. A view stays a function of its
/// state; the view model stays the only thing a test needs to check.
extension View {
    /// Everything inside is on this screen. Set by whoever builds the screen, above the screen's own
    /// view, so the screen's own body reads it too.
    public func trackingScreen(_ screen: String) -> some View {
        environment(\.trackingScope, .screen(screen))
    }

    /// Everything inside is in this list, on whatever screen it is on.
    public func trackingList(_ list: TrackingContext.List) -> some View {
        transformEnvironment(\.trackingScope) { $0 = $0.entering(list) }
    }

    /// Everything inside sits at this position in the list around it, counted from 0.
    public func trackingPosition(_ index: Int) -> some View {
        transformEnvironment(\.trackingScope) { $0 = $0.at(index) }
    }

    /// The screen came into view: every arrival, tab switches and navigating back included — but
    /// not the false one SwiftUI makes while the screen is being left. See `Presence`.
    public func onScreenAppear(perform action: @escaping (TrackingContext) -> Void) -> some View {
        modifier(ScreenAppearModifier(action: action))
    }

    /// At least half of this view came on screen. Seen means seen, not built: a lazy stack builds a
    /// row before it scrolls into view and again every time it scrolls back.
    /// It fires each time the view comes back into view, and each time is reported.
    public func onImpression(perform action: @escaping (TrackingContext) -> Void) -> some View {
        modifier(ImpressionModifier(action: action))
    }
}

private struct ScreenAppearModifier: ViewModifier {
    @Environment(\.trackingContext) private var context
    let action: (TrackingContext) -> Void

    @State private var presence = Presence()

    func body(content: Content) -> some View {
        content
            .onAppear {
                if presence.isArrival(at: .now) { action(context) }
            }
            .onDisappear { presence.left(at: .now) }
    }
}

private struct ImpressionModifier: ViewModifier {
    @Environment(\.trackingContext) private var context
    let action: (TrackingContext) -> Void

    /// Half, because that is the share of a card a shopper has to have in front of them to have seen
    /// what it is — the same line the ad industry draws for a view.
    static let threshold = 0.5

    @State private var presence = Presence()

    func body(content: Content) -> some View {
        content.onScrollVisibilityChange(threshold: Self.threshold) { isVisible in
            if !isVisible {
                presence.left(at: .now)
            } else if presence.isArrival(at: .now) {
                action(context)
            }
        }
    }
}
