import Combine
import Foundation
import Testing
import Session

/// The order things are asked in, and what happens when the answer is no. What makes an
/// address or a password acceptable belongs to `Email` and `Password` and is asserted in
/// their own suites — these check that the shop is only troubled once it is worth it.
@Suite("Signing in")
struct SigningInTests {

    @Test("A valid email and password reach the shop")
    func credentialsReachTheShop() async {
        let repository = RecordingSessionRepository()
        let logIn = DefaultLoginUseCase(sessionRepository: repository)

        _ = await logIn(email: Email("shopper@example.com"), password: Password("hunter2!!"))

        #expect(await repository.loginAttempts.map(\.email) == [Email("shopper@example.com")])
    }

    @Test("An address that is not an address is refused before the shop is troubled")
    func refusesInvalidEmail() async {
        let repository = RecordingSessionRepository()
        let logIn = DefaultLoginUseCase(sessionRepository: repository)

        let result = await logIn(email: Email("shopper"), password: Password("hunter2!!"))

        #expect(result.failure == .invalidEmail)
        #expect(await repository.loginAttempts.isEmpty)
    }

    @Test("A password that could not be right is refused before the shop is troubled")
    func refusesInvalidPassword() async {
        let repository = RecordingSessionRepository()
        let logIn = DefaultLoginUseCase(sessionRepository: repository)

        let result = await logIn(email: Email("shopper@example.com"), password: Password(tooShort))

        #expect(result.failure == .invalidPassword)
        #expect(await repository.loginAttempts.isEmpty)
    }

    @Test("The address is checked first, so a shopper is told one thing at a time")
    func addressIsCheckedFirst() async {
        let repository = RecordingSessionRepository()
        let logIn = DefaultLoginUseCase(sessionRepository: repository)

        #expect(await logIn(email: Email(""), password: Password("")).failure == .invalidEmail)
    }

    @Test("The shop's own refusal is passed on unchanged")
    func shopRefusal() async {
        let repository = RecordingSessionRepository()
        await repository.stub(login: .failure(.invalidCredentials))
        let logIn = DefaultLoginUseCase(sessionRepository: repository)

        let result = await logIn(email: Email("shopper@example.com"), password: Password("hunter2!!"))

        #expect(result.failure == .invalidCredentials)
    }
}

@Suite("Creating an account")
struct CreatingAnAccountTests {

    @Test("A complete sign-up reaches the shop")
    func reachesTheShop() async {
        let repository = RecordingSessionRepository()
        let createAccount = DefaultCreateAccountUseCase(sessionRepository: repository)

        _ = await createAccount(
            name: PersonName(first: "Ada", last: "Lovelace"),
            email: Email("ada@example.com"),
            password: Password("hunter2!!")
        )

        #expect(await repository.createAccountAttempts.map(\.email) == [Email("ada@example.com")])
    }

    @Test("A shopper with no name given is asked for one")
    func nameIsRequired() async {
        let repository = RecordingSessionRepository()
        let createAccount = DefaultCreateAccountUseCase(sessionRepository: repository)

        let result = await createAccount(
            name: PersonName(first: "   ", last: ""),
            email: Email("ada@example.com"),
            password: Password("hunter2!!")
        )

        #expect(result.failure == .nameIsMissing)
        #expect(await repository.createAccountAttempts.isEmpty)
    }

    @Test("A last name is optional — plenty of people have one name")
    func lastNameIsOptional() async {
        let repository = RecordingSessionRepository()
        let createAccount = DefaultCreateAccountUseCase(sessionRepository: repository)

        let result = await createAccount(
            name: PersonName(first: "Prince", last: ""),
            email: Email("prince@example.com"),
            password: Password("hunter2!!")
        )

        #expect(result.failure == nil)
    }

    @Test("Having no last name is absence, not an empty one to be checked for elsewhere")
    func noLastNameIsAbsent() {
        #expect(PersonName(first: "Prince", last: "").last == nil)
        #expect(PersonName(first: "Prince", last: "   ").last == nil)
        #expect(PersonName(first: "Prince", last: nil).full == "Prince")
        #expect(PersonName(first: "Ada", last: "Lovelace").full == "Ada Lovelace")
    }

    @Test("The same address and password rules apply as when signing in", arguments: [
        ("nonsense", "hunter2!!", CreateAccountError.invalidEmail),
        ("ada@example.com", tooShort, CreateAccountError.invalidPassword)
    ])
    func sameRulesAsSigningIn(email: String, password: String, expected: CreateAccountError) async {
        let repository = RecordingSessionRepository()
        let createAccount = DefaultCreateAccountUseCase(sessionRepository: repository)

        let result = await createAccount(
            name: PersonName(first: "Ada", last: nil),
            email: Email(email),
            password: Password(password)
        )

        #expect(result.failure == expected)
        #expect(await repository.createAccountAttempts.isEmpty)
    }

    @Test("The name is checked first, so a shopper is told one thing at a time")
    func nameIsCheckedFirst() async {
        let repository = RecordingSessionRepository()
        let createAccount = DefaultCreateAccountUseCase(sessionRepository: repository)

        let result = await createAccount(
            name: PersonName(first: "", last: nil),
            email: Email("nonsense"),
            password: Password("")
        )

        #expect(result.failure == .nameIsMissing)
    }
}

// MARK: -

/// Derived from the rule rather than written out, so raising or lowering the minimum
/// does not quietly turn these into tests of nothing.
private let tooShort = String(repeating: "a", count: Password.minimumLength - 1)

private actor RecordingSessionRepository: SessionRepository {
    private(set) var loginAttempts: [(email: Email, password: Password)] = []
    private(set) var createAccountAttempts: [(email: Email, password: Password)] = []

    private var loginResult: Result<Void, LoginError> = .success(())
    private var createAccountResult: Result<Void, CreateAccountError> = .success(())

    func stub(login: Result<Void, LoginError>) { loginResult = login }

    nonisolated var sessionPublisher: AnyPublisher<Session, Never> {
        Just(.guest).eraseToAnyPublisher()
    }

    nonisolated var currentSession: Session { .guest }

    func login(email: Email, password: Password) async -> Result<Void, LoginError> {
        loginAttempts.append((email, password))
        return loginResult
    }

    func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<Void, CreateAccountError> {
        createAccountAttempts.append((email, password))
        return createAccountResult
    }

    func logout() async {}
}

private extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
