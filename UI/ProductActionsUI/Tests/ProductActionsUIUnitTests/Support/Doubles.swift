import Combine
import Foundation
import Bag
import Money
import Product
import StockAlert
import Wishlist
import AuthUI
import SnackbarUI
@testable import ProductActionsUI

@MainActor
final class StubObserveBagItemQuantity: ObserveBagItemQuantityUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Int, Never>

    init(_ quantity: Int = 0) {
        subject = CurrentValueSubject(quantity)
    }

    func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never> { subject.eraseToAnyPublisher() }
}

@MainActor
final class SpyAddItemToBag: AddItemToBagUseCase, @unchecked Sendable {
    private(set) var added: [BagItem] = []

    func callAsFunction(_ item: BagItem) {
        added.append(item)
    }
}

@MainActor
final class SpyProductActionsNavigation: ProductActionsNavigation {
    private(set) var switchedToBagTab = false

    nonisolated func switchToBagTab() {
        MainActor.assumeIsolated { switchedToBagTab = true }
    }
}

@MainActor
final class SpySnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) {
        shown.append(snackbar)
    }
}

@MainActor
final class StubObserveWaitlistStatus: ObserveWaitlistStatusUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bool, Never>

    init(_ isWaiting: Bool = false) {
        subject = CurrentValueSubject(isWaiting)
    }

    func send(_ isWaiting: Bool) { subject.value = isWaiting }

    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}

@MainActor
final class StubSetStockAlert: SetStockAlertForProductUseCase, @unchecked Sendable {
    var result: Result<Void, StockAlertError> = .success(())
    var onSuccess: (Bool) -> Void = { _ in }
    private(set) var calls: [(productId: ProductID, isOn: Bool)] = []

    func callAsFunction(productId: ProductID, isOn: Bool) async -> Result<Void, StockAlertError> {
        calls.append((productId, isOn))
        await Task.yield()
        if case .success = result { onSuccess(isOn) }
        return result
    }
}

@MainActor
final class StubObserveProductIsWishlisted: ObserveProductIsWishlistedUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Bool, Never>

    init(_ isWishlisted: Bool = false) {
        subject = CurrentValueSubject(isWishlisted)
    }

    func send(_ isWishlisted: Bool) { subject.value = isWishlisted }

    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}

/// `onSuccess` is how a test makes a saved product start reading as saved. The real use case writes
/// through a repository that publishes what it kept, so anything observing it has heard before the
/// call returns; a stub that only counted calls could never show a caller reading state it had not
/// yet changed. The yield is the round trip: without a suspension here every call would finish
/// before the next one could start, and no ordering would ever be at stake.
@MainActor
final class StubAddProductToWishlist: AddProductToWishlistUseCase, @unchecked Sendable {
    var result: Result<Void, WishlistError> = .success(())
    var onSuccess: () -> Void = {}
    private(set) var calls: [ProductID] = []

    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError> {
        calls.append(productId)
        await Task.yield()
        if case .success = result { onSuccess() }
        return result
    }
}

@MainActor
final class StubRemoveProductFromWishlist: RemoveProductFromWishlistUseCase, @unchecked Sendable {
    var result: Result<Void, WishlistError> = .success(())
    var onSuccess: () -> Void = {}
    private(set) var calls: [ProductID] = []

    func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError> {
        calls.append(productId)
        await Task.yield()
        if case .success = result { onSuccess() }
        return result
    }
}

@MainActor
final class StubAuthPresenter: AuthPresenting {
    var signsIn = false
    private(set) var timesAsked = 0
    private let onSignIn: () -> Void

    init(onSignIn: @escaping () -> Void = {}) {
        self.onSignIn = onSignIn
    }

    func show(_ prompt: AuthenticationPrompt) async -> Bool {
        timesAsked += 1
        if signsIn { onSignIn() }
        return signsIn
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Product {
    static func fixture(id: Int, availability: Availability = .inStock(remaining: 10)) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: Money(amount: 9.99, currency: .usd),
            rating: 4.5,
            availability: availability,
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
