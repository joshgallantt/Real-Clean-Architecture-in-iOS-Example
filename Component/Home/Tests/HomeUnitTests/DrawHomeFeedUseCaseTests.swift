import Foundation
import Testing
import Product
@testable import Home

@Suite("Drawing Home's feed")
/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the acceptance suite says a shopper's
/// Home is broken; these say which rule did.
struct DrawHomeFeedUseCaseTests {
    private func makeUseCase(
        browseCatalog: StubBrowseCatalog = StubBrowseCatalog(),
        browseCategories: StubBrowseCategories = StubBrowseCategories()
    ) -> DrawHomeFeedUseCase {
        DefaultDrawHomeFeedUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)
    }

    @Test("Draws a carousel for each category that qualifies")
    func drawsACarouselPerQualifyingCategory() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(products(1...6, category: "beauty"))
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        let result = await useCase()

        #expect(result.value?.carousels.map(\.category.name) == ["Beauty"])
        #expect(browseCatalog.queries.first?.pageSize == 10)
    }

    @Test(
        "A category needs at least 5 products to earn a carousel, and a carousel never shows more than 10",
        arguments: [
            (available: 0, expectedShown: nil),
            (available: 4, expectedShown: nil),
            (available: 5, expectedShown: 5),
            (available: 6, expectedShown: 6),
            (available: 10, expectedShown: 10),
            (available: 15, expectedShown: 10)
        ] as [(available: Int, expectedShown: Int?)]
    )
    func floorAndCap(_ example: (available: Int, expectedShown: Int?)) async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty])
        let browseCatalog = StubBrowseCatalog()
        let stock = example.available > 0 ? products(1...example.available, category: "beauty") : []
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(stock)
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        let result = await useCase()

        if let expectedShown = example.expectedShown {
            #expect(result.value?.carousels.first?.products.count == expectedShown)
        } else {
            #expect(result.value == nil)
        }
    }

    @Test("Never draws more than 5 carousels, even when every category qualifies")
    func neverDrawsMoreThanFive() async {
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports, .toys, .books]
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success(categories)
        let browseCatalog = StubBrowseCatalog()
        for category in categories {
            browseCatalog.resultsByCategory[category.id] = .success(products(1...10, category: category.id.rawValue))
        }
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        let result = await useCase()

        #expect(result.value?.carousels.count == 5)
    }

    @Test("Never asks the same category for products twice")
    func neverTriesACategoryTwice() async {
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports, .toys, .books]
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success(categories)
        let browseCatalog = StubBrowseCatalog()
        for category in categories {
            browseCatalog.resultsByCategory[category.id] = .success(products(1...10, category: category.id.rawValue))
        }
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        _ = await useCase()

        let askedCategories = browseCatalog.queries.compactMap { query -> CategoryID? in
            guard case .category(let category) = query.filter else { return nil }
            return category.id
        }
        #expect(Set(askedCategories).count == askedCategories.count)
    }

    @Test("A category that falls short does not shrink the result, when another remains to try")
    func aShortfallIsBackfilledByAnotherCategory() async {
        let qualifying: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports]
        let short = ProductCategory.toys
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success(qualifying + [short])
        let browseCatalog = StubBrowseCatalog()
        for category in qualifying {
            browseCatalog.resultsByCategory[category.id] = .success(products(1...10, category: category.id.rawValue))
        }
        browseCatalog.resultsByCategory[short.id] = .success(products(1...3, category: short.id.rawValue))
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        let result = await useCase()

        #expect(Set(result.value?.carousels.map(\.category.id) ?? []) == Set(qualifying.map(\.id)))
    }

    @Test("A category that fails to load does not take down the categories that did")
    func aFailingCategoryIsDroppedSilently() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty, .fragrances])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .success(products(1...5, category: "beauty"))
        browseCatalog.resultsByCategory[.init(rawValue: "fragrances")] = .failure(.unavailable)
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        let result = await useCase()

        #expect(result.value?.carousels.map(\.category.name) == ["Beauty"])
    }

    @Test("If every category tried fails to load, Home has nothing to draw")
    func everyCategoryFailingLeavesNothingToDraw() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([.beauty, .fragrances])
        let browseCatalog = StubBrowseCatalog()
        browseCatalog.resultsByCategory[.init(rawValue: "beauty")] = .failure(.unavailable)
        browseCatalog.resultsByCategory[.init(rawValue: "fragrances")] = .failure(.unavailable)
        let useCase = makeUseCase(browseCatalog: browseCatalog, browseCategories: browseCategories)

        let result = await useCase()

        #expect(result.value == nil)
    }

    @Test("A shop that cannot even be asked for its categories leaves Home with nothing to draw")
    func cannotReachCategoriesLeavesNothingToDraw() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .failure(.unavailable)
        let useCase = makeUseCase(browseCategories: browseCategories)

        let result = await useCase()

        #expect(result.value == nil)
    }

    @Test("A shop with no categories to organise into leaves Home with nothing to draw")
    func noCategoriesLeavesNothingToDraw() async {
        let browseCategories = StubBrowseCategories()
        browseCategories.result = .success([])
        let useCase = makeUseCase(browseCategories: browseCategories)

        let result = await useCase()

        #expect(result.value == nil)
    }
}

@Suite("A home feed")
/// The invariant `HomeFeed` leans on: it cannot be built with nothing in it, so a draw that came
/// back with nothing has no feed to hand back.
struct HomeFeedTests {
    @Test("A feed with no carousels is not a feed")
    func noCarouselsIsNotAFeed() {
        #expect(HomeFeed(carousels: []) == nil)
    }

    @Test("A feed keeps the carousels it was drawn with, in order")
    func keepsItsCarouselsInOrder() {
        let beauty = HomeCarousel(category: .beauty, products: products(1...5, category: "beauty"))
        let fragrances = HomeCarousel(category: .fragrances, products: products(101...105, category: "fragrances"))

        #expect(HomeFeed(carousels: [beauty, fragrances])?.carousels == [beauty, fragrances])
    }
}

private extension Result {
    var value: Success? { try? get() }
}
