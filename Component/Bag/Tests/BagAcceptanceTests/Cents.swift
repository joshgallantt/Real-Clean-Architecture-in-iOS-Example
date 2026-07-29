/// Money compared in cents. `Double` cannot represent 9.99 exactly, so adding prices
/// drifts — 9.99 + 49.99 comes out as 59.980000000000004. The bag's arithmetic is
/// right; the type it is done in is not.
extension Double {
    var cents: Int { Int((self * 100).rounded()) }
}
