import SwiftUI
import SheetUI

@MainActor
public final class SheetPresenter: ObservableObject, SheetPresenting {
    @Published var presentation: SheetPresentation?

    private var dismissalHandler: (() -> Void)?
    private var queued: SheetPresentation?

    public init() {}

    public func present<Content: View>(onDismiss: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        let next = SheetPresentation(content: AnyView(content()), onDismiss: onDismiss)

        guard presentation != nil else {
            show(next)
            return
        }

        queued = next
        dismissalHandler = nil
        presentation = nil
    }

    public func dismiss() {
        queued = nil
        dismissalHandler = nil
        presentation = nil
    }

    func sheetDidDismiss() {
        let handler = dismissalHandler
        dismissalHandler = nil

        if let next = queued {
            queued = nil
            show(next)
        }

        handler?()
    }

    private func show(_ next: SheetPresentation) {
        presentation = next
        dismissalHandler = next.onDismiss
    }
}
