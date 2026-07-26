import SwiftUI

/// Every step is a form on a sheet, so every step shares a problem: the keyboard takes half
/// the screen, and SwiftUI's answer — left to itself — is to slide the whole sheet upward
/// until the header has gone off the top of it. Scrolling content inside a frame that holds
/// still is what stops that. The sheet stays put and the fields come to the caret.
struct AuthFormScaffold<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity)
                .padding(24)
        }
        // Nothing to bounce against when the form is shorter than the sheet.
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }
}
