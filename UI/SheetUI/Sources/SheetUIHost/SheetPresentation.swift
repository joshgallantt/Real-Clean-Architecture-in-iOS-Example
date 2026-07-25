import SwiftUI

/// One turn on screen: the content to show, and what to tell the caller if the user is the
/// one who ends it. Identity is per-presentation so SwiftUI treats each as a distinct sheet.
struct SheetPresentation: Identifiable {
    let id = UUID()
    let content: AnyView
    let onDismiss: (() -> Void)?
}
