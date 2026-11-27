import Foundation

/// Fowler, *PoEAA* (2002), Ch. 15 — Data Transfer Object: a vendor's payload, as the JSON it would
/// be sent as. Each destination's mapper builds one in its own vendor's shape; none of them shares
/// a shape, so what they share is only what JSON is made of.
enum JSONValue: Encodable, Equatable {
    case string(String)
    case integer(Int)
    case number(Decimal)
    case array([JSONValue])
    case object([String: JSONValue])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .integer(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    /// One sorted-key line, so the same payload is always the same text.
    var line: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
