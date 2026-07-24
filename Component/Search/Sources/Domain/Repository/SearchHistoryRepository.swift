public protocol SearchHistoryRepository: Sendable {
    func getRecentSearches() async -> [String]
    func recordSearch(_ query: String) async
    func clearRecentSearches() async
}
