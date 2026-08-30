// Shared between this package's test suites. Xcode refuses a test target
// that depends on another test target, so code two suites both need has to
// be an ordinary module — marked visible to tests alone, which is what keeps
// it out of the app.

import SnackbarUITestSupport
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
final class SpyProductActionsNavigation: ProductActionsNavigation {
    private(set) var switchedToBagTab = false

    nonisolated func switchToBagTab() {
        MainActor.assumeIsolated { switchedToBagTab = true }
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
final class StubSetProductIsWishlisted: SetProductIsWishlistedUseCase, @unchecked Sendable {
    var result: Result<Void, WishlistError> = .success(())
    var onSuccess: (Bool) -> Void = { _ in }
    private(set) var calls: [(productId: ProductID, isWishlisted: Bool)] = []

    func callAsFunction(
        productId: ProductID,
        isWishlisted: Bool
    ) async -> Result<Void, WishlistError> {
        calls.append((productId, isWishlisted))
        await Task.yield()
        if case .success = result { onSuccess(isWishlisted) }
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
