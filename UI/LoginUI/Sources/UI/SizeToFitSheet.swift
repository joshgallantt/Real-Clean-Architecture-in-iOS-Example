import SwiftUI

/// Sizes a sheet on iPhone to the natural height of its content. iOS has no built-in
/// "shrink to content" detent for compact-width sheets — `presentationSizing(.fitted)`
/// has no effect on iPhone (it's iPad/Mac only), so the content's ideal height is
/// measured and applied as a fixed `.height` presentation detent instead.
struct SizeToFitSheetModifier: ViewModifier {
    @State private var contentHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            // The measurement must not react to the keyboard's safe-area inset, or the
            // detent would change while a field is focused, resigning first responder
            // and dismissing the keyboard.
            .ignoresSafeArea(.keyboard)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newHeight in
                contentHeight = newHeight
            }
            .presentationDetents(contentHeight.map { [.height($0)] } ?? [.medium])
            .presentationDragIndicator(.visible)
    }
}

extension View {
    func sizeToFitSheet() -> some View {
        modifier(SizeToFitSheetModifier())
    }
}
