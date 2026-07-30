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
final class MainViewModel: ObservableObject {
    enum Phase: Hashable {
        case splash
        case welcome
        case onboarding
        case main
    }

    @Published private(set) var phase: Phase = .splash

    private let getSession: GetSessionUseCase

    private let splashDuration: Duration = .seconds(1.2)

    private let settleAfterAuthentication: Duration = .milliseconds(500)

    init(getSession: GetSessionUseCase) {
        self.getSession = getSession
    }

    func onAppear() async {
        guard phase == .splash else { return }
        try? await Task.sleep(for: splashDuration)
        guard phase == .splash else { return }
        phase = getSession().isLoggedIn ? .main : .welcome
    }

    func continueAsGuest() {
        phase = .main
    }

    func authenticationFinished() {
        Task {
            try? await Task.sleep(for: settleAfterAuthentication)
            phase = .main
        }
    }
}
