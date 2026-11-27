import SwiftUI
import Testing
import Tracking
import UIKit
@testable import TrackingUI

@MainActor
@Observable
private final class Journey {
    var tab = 0
    var path: [Int] = []
    var screens: [String] = []
    var cardsSeen = 0
}

/// The shape the app has: tabs, each a navigation stack pushed by its path, a screen that reports
/// its arrival and cards that report being seen.
private struct Shop: View {
    @Bindable var journey: Journey

    var body: some View {
        TabView(selection: $journey.tab) {
            Tab("Home", systemImage: "house", value: 0) {
                NavigationStack(path: $journey.path) {
                    ScrollView {
                        Text("card")
                            .frame(height: 80)
                            .onImpression { _ in journey.cardsSeen += 1 }
                    }
                    .onScreenAppear { journey.screens.append($0.screen) }
                    .trackingScreen("home")
                    .navigationDestination(for: Int.self) { _ in
                        Text("product")
                            .onScreenAppear { journey.screens.append($0.screen) }
                            .trackingScreen("product")
                    }
                }
            }
            Tab("Bag", systemImage: "bag", value: 1) {
                Text("bag")
                    .onScreenAppear { journey.screens.append($0.screen) }
                    .trackingScreen("bag")
            }
        }
    }
}

/// Real SwiftUI, hosted in a window, because what is being pinned is what SwiftUI itself calls.
@MainActor
@Suite("A shopper's journey is reported as they made it, on real SwiftUI")
struct ReportingAJourneyTests {
    private let journey = Journey()
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))

    private func show() async {
        window.rootViewController = UIHostingController(rootView: Shop(journey: journey))
        window.makeKeyAndVisible()
        await settle()
    }

    /// Long enough for a push to finish animating, which is when the screen underneath finally goes.
    private func settle() async {
        try? await Task.sleep(for: .milliseconds(1500))
    }

    @Test("Opening a product is the product viewed, not the screen being left viewed a second time")
    func pushing() async {
        await show()

        journey.path = [1]
        await settle()

        #expect(journey.screens == ["home", "product"])
        #expect(journey.cardsSeen == 1)
    }

    @Test("Going back is the screen viewed again, and what is on it seen again")
    func goingBack() async {
        await show()
        journey.path = [1]
        await settle()

        journey.path = []
        await settle()

        #expect(journey.screens == ["home", "product", "home"])
        #expect(journey.cardsSeen == 2)
    }

    @Test("Switching tabs and back is each screen viewed as it is arrived at")
    func switchingTabs() async {
        await show()

        journey.tab = 1
        await settle()
        journey.tab = 0
        await settle()

        #expect(journey.screens == ["home", "bag", "home"])
        #expect(journey.cardsSeen == 2)
    }
}
