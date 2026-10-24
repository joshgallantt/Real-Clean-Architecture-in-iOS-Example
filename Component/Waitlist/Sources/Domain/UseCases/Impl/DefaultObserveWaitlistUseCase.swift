import Combine

public struct DefaultObserveWaitlistUseCase: ObserveWaitlistUseCase {
    private let repository: WaitlistRepository

    public init(repository: WaitlistRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Waitlist, Never> {
        repository.waitlistPublisher
    }
}
