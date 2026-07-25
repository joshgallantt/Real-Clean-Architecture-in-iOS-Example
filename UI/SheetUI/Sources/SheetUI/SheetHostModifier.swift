import SwiftUI

private struct SheetHostModifier: ViewModifier {
    @ObservedObject var coordinator: SheetCoordinator

    func body(content: Content) -> some View {
        content
            .sheet(item: $coordinator.step, onDismiss: {
                coordinator.handleSheetDismissed()
            }) { step in
                step.content
            }
    }
}

public extension View {
    /// Hosts whatever `coordinator` is asked to present.
    func sheetHost(_ coordinator: SheetCoordinator) -> some View {
        modifier(SheetHostModifier(coordinator: coordinator))
    }
}
