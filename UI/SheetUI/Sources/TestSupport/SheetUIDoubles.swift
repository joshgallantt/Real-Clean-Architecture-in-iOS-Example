import SheetUI
import SwiftUI

@MainActor
public final class SpySheetPresenter: SheetPresenting {
    public init() {}

    public private(set) var presentCount = 0
    private var lastOnDismiss: (() -> Void)?

    public func present<Content: View>(onDismiss: (() -> Void)?, content: () -> Content) {
        presentCount += 1
        lastOnDismiss = onDismiss
    }

    public func dismiss() {}

    public func userDismissedTheSheet() {
        lastOnDismiss?()
    }
}
