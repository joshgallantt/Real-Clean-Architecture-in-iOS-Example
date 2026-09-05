import SheetUI
import SwiftUI

@MainActor
public final class SpySheetPresenting: SheetPresenting {
    public init() {}

    public private(set) var presentCount = 0
    private var lastOnDismiss: (() -> Void)?
    private var announcePresented: CheckedContinuation<Void, Never>?

    /// Returns once a sheet is up and waiting on the shopper.
    ///
    /// A caller that presents a sheet does not come back until the sheet is
    /// dismissed, so a test cannot await that work before dismissing it — that
    /// waits for something only the next line makes possible. This is the point
    /// to wait for instead.
    public func untilPresented() async {
        guard lastOnDismiss == nil else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            announcePresented = continuation
        }
    }

    public func present<Content: View>(onDismiss: (() -> Void)?, content: () -> Content) {
        presentCount += 1
        lastOnDismiss = onDismiss
        announcePresented?.resume()
        announcePresented = nil
    }

    public func dismiss() {}

    public func userDismissedTheSheet() {
        lastOnDismiss?()
    }
}
