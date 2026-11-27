/// Somewhere a line of text can be written. Told text, so it cannot have an opinion about what an
/// event is.
public protocol LoggerClient: Sendable {
    func log(_ line: String)
}
