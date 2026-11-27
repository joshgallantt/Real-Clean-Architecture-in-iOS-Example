import SwiftUI
import Tracking

/// Where in the view tree a view is, as far as tracking is concerned: nowhere yet, on a screen, in a
/// list on a screen, or at a position in that list. Each level is set by the view that knows it —
/// the screen by whoever builds the screen, the list by the list, the position by the row — and read
/// by whatever is drawn inside.
enum TrackingScope: Equatable {
    case noScreen
    case screen(String)
    case list(String, TrackingContext.List)
    case position(String, TrackingContext.List, Int)

    /// What an event here is reported against. A list without a position is just the screen it is on
    /// — a "View All" in a carousel's heading is not in the carousel.
    var context: TrackingContext {
        switch self {
        case .noScreen: .screen("")
        case .screen(let screen), .list(let screen, _): .screen(screen)
        case .position(let screen, let list, let index): .list(screen, list, index: index)
        }
    }

    func entering(_ list: TrackingContext.List) -> TrackingScope {
        switch self {
        case .noScreen: .noScreen
        case .screen(let screen), .list(let screen, _), .position(let screen, _, _): .list(screen, list)
        }
    }

    func at(_ index: Int) -> TrackingScope {
        switch self {
        case .list(let screen, let list), .position(let screen, let list, _): .position(screen, list, index)
        case .noScreen, .screen: self
        }
    }
}

extension EnvironmentValues {
    @Entry var trackingScope: TrackingScope = .noScreen

    /// Where an event from this view would be reported: the screen it is on, or its position in a
    /// list. A view reads it and hands it to its view model with what happened.
    public var trackingContext: TrackingContext { trackingScope.context }
}
