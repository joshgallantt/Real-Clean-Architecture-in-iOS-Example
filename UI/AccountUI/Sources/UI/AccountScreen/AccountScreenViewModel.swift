import Combine
import Foundation
import Session

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class AccountScreenViewModel: ObservableObject {
    @Published private(set) var session: Session = .guest

    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private var cancellables = Set<AnyCancellable>()

    var currentUser: User? { session.user }

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
    }

    func onAppear() {
        session = getSession()

        guard cancellables.isEmpty else { return }
        observeSession()
            .sink { [weak self] session in
                self?.session = session
            }
            .store(in: &cancellables)
    }

    func didTapLogOut() async {
        await logoutUseCase()
    }
}
