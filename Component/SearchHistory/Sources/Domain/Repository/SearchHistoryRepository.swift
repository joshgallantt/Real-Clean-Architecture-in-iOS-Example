/// Access to the shopper's recent searches, and nothing else. What counts as a search
/// worth remembering is `SearchHistory`'s business.
public protocol SearchHistoryRepository: Sendable {
    func history() async -> SearchHistory
    func save(_ history: SearchHistory) async
}
