import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule, named
/// for what a shopper's Home does once per visit — draw a feed.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Aggregates: "control all access to the objects
/// inside the boundary through the root." Home reaches `Component/Product` through the two use
/// cases it publishes, never around them into its repository.
public protocol DrawHomeFeedUseCase: Sendable {
    func callAsFunction() async -> Result<HomeFeed, HomeError>
}
