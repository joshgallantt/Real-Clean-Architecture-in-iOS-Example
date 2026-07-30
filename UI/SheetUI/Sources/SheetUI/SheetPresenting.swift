import SwiftUI

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle; Fowler, *PoEAA*
/// (2002) — Separated Interface: a feature asks for the effect it wants without depending on
/// whatever presents it.
public protocol SheetPresenting: AnyObject {
    func present<Content: View>(onDismiss: (() -> Void)?, @ViewBuilder content: () -> Content)

    func dismiss()
}

public extension SheetPresenting {
    func present<Content: View>(@ViewBuilder content: () -> Content) {
        present(onDismiss: nil, content: content)
    }
}
