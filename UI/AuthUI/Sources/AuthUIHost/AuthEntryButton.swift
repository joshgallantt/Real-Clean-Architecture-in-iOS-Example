import SwiftUI
import Tracking
import TrackingUI

/// A way into signing in that another feature draws on its own screen — Log In on Account. Which
/// screen that is comes from the environment the button is drawn into, so a Log In on Account and
/// one anywhere else are the same button and two different places to have been persuaded.
@MainActor
@Observable
final class AuthEntryButtonViewModel {
    /// The work the last tap started, so a test can wait for exactly that.
    @ObservationIgnored private(set) var inFlight: Task<Void, Never>?

    private let element: String
    private let authenticate: @MainActor () async -> Bool
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let onAuthenticated: () -> Void

    init(
        element: String,
        authenticate: @escaping @MainActor () async -> Bool,
        trackElementInteraction: TrackElementInteractionUseCase,
        onAuthenticated: @escaping () -> Void
    ) {
        self.element = element
        self.authenticate = authenticate
        self.trackElementInteraction = trackElementInteraction
        self.onAuthenticated = onAuthenticated
    }

    func didTap(in context: TrackingContext) {
        trackElementInteraction(element, in: context)
        inFlight = Task {
            if await authenticate() { onAuthenticated() }
        }
    }
}

struct AuthEntryButton: View {
    @Environment(\.trackingContext) private var trackingContext
    @State var viewModel: AuthEntryButtonViewModel
    let title: String

    var body: some View {
        Button {
            viewModel.didTap(in: trackingContext)
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
    }
}
