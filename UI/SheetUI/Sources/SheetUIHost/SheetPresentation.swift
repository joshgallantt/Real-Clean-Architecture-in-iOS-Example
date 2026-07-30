import SwiftUI

struct SheetPresentation: Identifiable {
    let id = UUID()
    let content: AnyView
    let onDismiss: (() -> Void)?
}
