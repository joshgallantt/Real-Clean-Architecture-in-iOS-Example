import SwiftUI
import Tracking
import TrackingUI

/// A row drawn by a function of the screen rather than a view of its own still has to know where it
/// is — which list, which position — when it is tapped. This reads that from the environment the row
/// is placed in and hands it to the row, so the screen does not have to split every row into a type.
struct TrackingContextReader<Content: View>: View {
    @Environment(\.trackingContext) private var trackingContext
    let content: (TrackingContext) -> Content

    var body: some View {
        content(trackingContext)
    }
}
