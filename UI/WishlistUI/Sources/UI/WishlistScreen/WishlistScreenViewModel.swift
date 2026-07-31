import Combine
import Foundation
import Session

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 7 — Single Responsibility Principle: whether there is anybody to show a list to. It
/// used to hold the list as well, which meant a second list on the tab would have made it hold two
/// — so the lists moved to `SavedProductsViewModel`, one instance each, and this kept the one thing
/// that is about the tab rather than about either list.
public final class WishlistScreenViewModel: ObservableObject {
    @Published private(set) var isAuthenticated = false

    private let observeSession: ObserveSessionUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(observeSession: ObserveSessionUseCase) {
        self.observeSession = observeSession
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeSession()
            .sink { [weak self] session in
                self?.isAuthenticated = session.isLoggedIn
            }
            .store(in: &cancellables)
    }
}
