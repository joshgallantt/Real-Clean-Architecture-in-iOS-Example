import Foundation
import Testing
import Product
@testable import ProductUI

@MainActor
@Suite("Product details")
struct ProductDetailsViewModelTests {
    @Test("Given a product already in hand, there is nothing to appear and load")
    func givenAProductThereIsNothingToLoad() async {
        let viewModel = ProductDetailsViewModel(product: .fixture(id: 1))

        #expect(viewModel.product == .fixture(id: 1))
        #expect(viewModel.isLoading == false)
    }

    @Test("Given only an id, appearing looks the product up")
    func givenOnlyAnIdAppearingLooksItUp() async {
        let viewProduct = StubViewProduct()
        viewProduct.result = .success(.fixture(id: 1))
        let viewModel = ProductDetailsViewModel(id: pid(1), viewProduct: viewProduct)

        await viewModel.onAppear()

        #expect(viewProduct.calls == [pid(1)])
        #expect(viewModel.product == .fixture(id: 1))
        #expect(viewModel.isLoading == false)
        #expect(viewModel.loadFailed == false)
    }

    @Test("Given a product already in hand, appearing changes nothing about it")
    func givenAProductAppearingChangesNothing() async {
        let viewModel = ProductDetailsViewModel(product: .fixture(id: 1))

        await viewModel.onAppear()

        #expect(viewModel.product == .fixture(id: 1))
        #expect(viewModel.loadFailed == false)
    }

    @Test("A product that cannot be found is reported as a failed load")
    func notFoundIsAFailedLoad() async {
        let viewProduct = StubViewProduct()
        viewProduct.result = .failure(.notFound)
        let viewModel = ProductDetailsViewModel(id: pid(1), viewProduct: viewProduct)

        await viewModel.onAppear()

        #expect(viewModel.product == nil)
        #expect(viewModel.loadFailed)
    }

    @Test("Appearing again once it has already loaded asks the use case nothing more")
    func appearingAgainAsksNothingMore() async {
        let viewProduct = StubViewProduct()
        viewProduct.result = .success(.fixture(id: 1))
        let viewModel = ProductDetailsViewModel(id: pid(1), viewProduct: viewProduct)
        await viewModel.onAppear()

        await viewModel.onAppear()

        #expect(viewProduct.calls.count == 1)
    }
}
