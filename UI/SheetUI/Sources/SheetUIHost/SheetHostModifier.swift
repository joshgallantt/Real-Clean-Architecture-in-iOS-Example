import SwiftUI

private struct SheetHostModifier: ViewModifier {
    @ObservedObject var presenter: SheetPresenter

    func body(content: Content) -> some View {
        content
            .sheet(item: $presenter.presentation, onDismiss: presenter.sheetDidDismiss) { presentation in
                presentation.content
            }
    }
}

public extension View {
    /// Hosts whatever `presenter` is asked to present.
    func sheetHost(_ presenter: SheetPresenter) -> some View {
        modifier(SheetHostModifier(presenter: presenter))
    }
}
