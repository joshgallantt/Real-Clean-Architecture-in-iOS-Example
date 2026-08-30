import Combine
import Foundation
import Settings

// Shared between this package's unit and snapshot suites. Xcode refuses a test
// target that depends on another test target, so code two suites both need has
// to be an ordinary module — and the architecture rules mark this one visible
// to tests alone, which is what keeps it out of the app.

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}
