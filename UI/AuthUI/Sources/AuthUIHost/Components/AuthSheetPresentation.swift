import SwiftUI

extension View {
    /// The presentation chrome every sheet in the authentication flow shares: a fixed height,
    /// content centred in it, and the close button in the sheet's own top-trailing corner.
    /// The button is pinned to the sheet rather than to the content, so it stays put when the
    /// content changes — a form giving way to its confirmation, or one sheet to the next.
    /// Only the height differs, because only the content does.
    func authSheetPresentation(height: CGFloat) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) { AuthSheetCloseButton() }
            .presentationDetents([.height(height)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
    }
}
