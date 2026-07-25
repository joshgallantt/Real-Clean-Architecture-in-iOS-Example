import SwiftUI

private struct SheetContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Sizes the sheet to the natural height of its content rather than the full screen.
/// Only works for content that doesn't itself expand to fill available space (e.g. a
/// VStack, not a Form/List).
struct SizeToFitSheetModifier: ViewModifier {
    @State private var contentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: SheetContentHeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(SheetContentHeightKey.self) { contentHeight = $0 }
            .presentationDetents([.height(contentHeight)])
            .presentationDragIndicator(.visible)
    }
}

extension View {
    func sizeToFitSheet() -> some View {
        modifier(SizeToFitSheetModifier())
    }
}
