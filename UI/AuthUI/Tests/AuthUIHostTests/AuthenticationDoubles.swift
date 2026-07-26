import Session
@testable import AuthUIDI

struct StubLoginUseCase: LoginUseCase {
    let result: Result<Void, LoginError>

    func callAsFunction(email: String, password: String) async -> Result<Void, LoginError> {
        result
    }
}

struct StubCreateAccountUseCase: CreateAccountUseCase {
    let result: Result<Void, CreateAccountError>

    func callAsFunction(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError> {
        result
    }
}

struct StubGetSessionUseCase: GetSessionUseCase {
    let session: Session

    @MainActor
    func callAsFunction() -> Session {
        session
    }
}

struct StubUserIsLoggedInUseCase: UserIsLoggedInUseCase {
    let isLoggedIn: Bool

    @MainActor
    func callAsFunction() async -> Bool {
        isLoggedIn
    }
}

extension Session {
    static let josh = Session.authenticated(
        User(id: 1, email: "josh@example.com", firstName: "Josh", lastName: "Gallant")
    )
}

@MainActor
func makeLogInStep(
    result: Result<Void, LoginError> = .success(()),
    session: Session = .josh
) -> LogInStepViewModel {
    LogInStepViewModel(
        loginUseCase: StubLoginUseCase(result: result),
        getSession: StubGetSessionUseCase(session: session)
    )
}

@MainActor
func makeCreateAccountStep(
    result: Result<Void, CreateAccountError> = .success(()),
    session: Session = .josh
) -> CreateAccountStepViewModel {
    CreateAccountStepViewModel(
        createAccountUseCase: StubCreateAccountUseCase(result: result),
        getSession: StubGetSessionUseCase(session: session)
    )
}
