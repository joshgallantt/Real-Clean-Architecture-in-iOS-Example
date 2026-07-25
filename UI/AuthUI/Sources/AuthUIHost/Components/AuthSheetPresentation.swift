import SwiftUI

extension View {
    /// The presentation chrome every sheet in the authentication flow shares. Only the
    /// height differs, because only the content does.
    func authSheetPresentation(height: CGFloat) -> some View {
        presentationDetents([.height(height)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
    }
}
