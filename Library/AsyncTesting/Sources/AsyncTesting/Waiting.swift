/// Waiting for work a screen started but did not wait for itself.
///
/// A view model that kicks off a `Task` has returned before the work is done, so
/// a test has to give the runtime somewhere to run it. This is a `Library/`
/// package rather than any component's test support because nothing here knows
/// what a bag or an order is — the same reason `Networking` lives here.
///
/// It exists at all because the same three lines had been written into five
/// packages, identically, and one of the five had already been found wanting
/// without the others hearing about it.
public enum AsyncTesting {}

/// Waits until the condition holds, or gives up.
///
/// Prefer this to `settle()`. It waits on the thing the test cares about, so it
/// stops as soon as that is true and only spins the full count when something
/// is genuinely wrong. A count of yields, by contrast, is a guess about how
/// busy the machine is.
@MainActor
public func yieldUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<1_000 where !isSatisfied() { await Task.yield() }
}

/// Yields a fixed number of times and hopes it was enough.
///
/// Kept because several suites use it and it works, but it is the weaker of the
/// two and should not be reached for in new tests. `OrderUI` learned why: three
/// of its tests failed exactly once, on the run straight after a full rebuild,
/// and passed every run before and since. A test that passes because the CPU
/// happened to be free is not passing — it is being lucky where you cannot see
/// it, and the longest path is the one a fixed count loses first.
///
/// Where you can name the condition you are waiting for, `yieldUntil` says what
/// you meant and stops when it is true.
@MainActor
public func settle() async {
    for _ in 0..<200 { await Task.yield() }
}
