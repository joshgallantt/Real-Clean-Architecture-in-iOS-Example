# Clean Architecture for iOS

A practical implementation of Clean Architecture in SwiftUI, demonstrating how to structure an iOS application with clear separation of concerns, testability, and maintainability. The architecture is grounded in principles from Robert C. Martin's *Clean Architecture* (2017), Eric Evans' *Domain-Driven Design* (2003), and Martin Fowler's *Patterns of Enterprise Application Architecture* (2002).

---

## Architecture Principles

### The Dependency Rule

> *"Source code dependencies must point only inward, toward higher-level policies."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 15

Dependencies point inward. The domain layer knows nothing about the data or presentation layers. The data layer knows about the domain but not the UI. The presentation layer depends on the domain but not on any specific data source.

```
Presentation ──▶ Domain ◀── Data
     └──────────────────────────▶ (never)
```

This ensures business logic can be tested without a simulator, a network connection, or a database.

### SOLID Principles

Robert C. Martin introduced the SOLID principles in *Agile Software Development, Principles, Patterns, and Practices* (2002). This project applies them as follows:

- **Single Responsibility** — Each class has one reason to change. `LoginScreenViewModel` manages login UI state. `DefaultUserRepository` manages user data access. Neither does both.
- **Open/Closed** — Behaviour is extended through protocols, not modification. Adding a new `AuthClient` implementation requires no changes to `DefaultUserRepository`.
- **Liskov Substitution** — `FakeAuthClient` is a drop-in replacement for any real `AuthClient`. ViewModels accept any `UserLoginUseCase`, not a concrete class.
- **Interface Segregation** — Navigation protocols are small and feature-scoped. `HomeNavigation` only exposes navigation methods relevant to the Home feature.
- **Dependency Inversion** — High-level modules (`DefaultUserRepository`) depend on abstractions (`AuthClient`, `UserSession`), not on concretions.

### Repository Pattern

> *"A Repository mediates between the domain and data mapping layers, acting like an in-memory collection of domain objects."*
> — Martin Fowler, *Patterns of Enterprise Application Architecture* (2002), Chapter 10

Repository protocols are defined in the domain layer. Implementations live in the data layer. The domain never knows how data is fetched or stored.

### Separation of Concerns

> *"Gather together the things that change for the same reasons. Separate things that change for different reasons."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 7

Each module has a single axis of change. UI modules change when screens change. Domain modules change when business rules change. Data modules change when external systems change. These reasons are independent.

---

## Project Structure

```
├── User/                    # Domain & Data layer (Swift Package)
│   ├── Domain/              # Entities, use cases, repository contracts
│   ├── Data/                # Repository implementations, data sources
│   └── DI/                  # Dependency injection for User module
├── LoginUI/                 # Login feature (Swift Package)
├── HomeUI/                  # Home feature (Swift Package)
├── WishlistUI/              # Wishlist feature (Swift Package)
├── CartUI/                  # Cart feature (Swift Package)
└── iPhone/                  # Application layer — composition root
    ├── Injector.swift        # Wires all dependencies together
    ├── Navigation/           # Navigator and Destination
    └── Main/                 # App entry point and tab screen
```

---

## Architecture Layers

```
┌──────────────────────────────────────────┐
│          Application Layer               │  Composition root. Wires all
│       iPhone/Injector, Navigator         │  dependencies. Not testable by
│                                          │  design — it is pure wiring.
├──────────────────────────────────────────┤
│          Presentation Layer              │  MVVM. Views are passive.
│       *UI feature modules                │  ViewModels hold UI state and
│       Views + ViewModels + DI            │  delegate to use cases.
├──────────────────────────────────────────┤
│           Domain Layer                   │  Pure Swift. Zero framework
│       User/Domain — Entities,            │  dependencies. The stable core
│       Use Cases, Repository Contracts    │  of the application.
├──────────────────────────────────────────┤
│            Data Layer                    │  Implements domain contracts.
│       User/Data — Repositories,          │  Knows about networking,
│       Data Sources, DTOs                 │  persistence, and sessions.
└──────────────────────────────────────────┘
```

---

## Domain Layer

The domain layer contains pure business logic with **zero dependencies** on external frameworks, UI, or data sources. It can be compiled, tested, and reasoned about in isolation.

### Entities

> *"An object primarily defined by its identity is called an Entity."*
> — Eric Evans, *Domain-Driven Design* (2003), Chapter 5

Entities are the core business objects. They are framework-independent and carry no persistence or UI concerns.

**[`User/Sources/Domain/Model/User.swift`](User/Sources/Domain/Model/User.swift)**
```swift
public struct User: Equatable, Sendable {
    public let id: UUID
    public let username: String
}
```

### Use Cases

> *"Use cases contain application-specific business rules... They orchestrate the flow of data to and from the entities."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 16

Each use case protocol represents one specific business operation. Protocols allow the presentation layer to depend on the operation's contract, not on any implementation detail.

**[`User/Sources/Domain/UseCases/UserLoginUseCase.swift`](User/Sources/Domain/UseCases/UserLoginUseCase.swift)**
```swift
public protocol UserLoginUseCase {
    @MainActor
    func execute(username: String, password: String) async -> Result<Void, LoginError>
}
```

- `UserIsLoggedInUseCase` — synchronous check of current login state
- `ObserveUserIsLoggedInUseCase` — reactive stream of login state changes

### Repository Contracts

Repository protocols are defined here in the domain layer — not in the data layer. This is the inversion of control that the Dependency Rule requires.

**[`User/Sources/Domain/Repository/UserRepository.swift`](User/Sources/Domain/Repository/UserRepository.swift)**
```swift
public protocol UserRepository {
    @MainActor
    var loggedInPublisher: AnyPublisher<Bool, Never> { get }
    @MainActor
    func login(username: String, password: String) async -> Result<Void, LoginError>
    @MainActor
    func logout() async
}
```

---

## Data Layer

The data layer implements domain contracts and handles all external data concerns — network, session, persistence. It depends on the domain layer but the domain layer has no knowledge of it.

### Repository Implementation

`DefaultUserRepository` coordinates between data sources, maps errors to domain types, and satisfies the `UserRepository` contract.

**[`User/Sources/Data/DefaultUserRepository.swift`](User/Sources/Data/DefaultUserRepository.swift)**
```swift
public final class DefaultUserRepository: UserRepository {
    private let session: UserSession
    private let authClient: AuthClient

    public func login(username: String, password: String) async -> Result<Void, LoginError> {
        let result = await authClient.login(username: username, password: password)
        switch result {
        case let .success((user, token)):
            session.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(mapAuthClientErrorToLoginError(error))
        }
    }
}
```

Error mapping at the boundary ensures domain types never leak infrastructure-specific error codes.

### Data Sources

Data sources are also protocol-driven, keeping the repository testable independently of the network or session implementation.

**[`User/Sources/Data/Auth/AuthClient.swift`](User/Sources/Data/Auth/AuthClient.swift)**
```swift
public protocol AuthClient: Sendable {
    func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
```

**[`User/Sources/Data/Session/UserSession.swift`](User/Sources/Data/Session/UserSession.swift)**
```swift
@MainActor
public protocol UserSession: AnyObject {
    var user: User? { get }
    var isLoggedInPublisher: AnyPublisher<Bool, Never> { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}
```

`FakeAuthClient` is the default implementation — an `actor` that simulates authentication without a real backend. Swap it for any `AuthClient` conformance to connect to a real API.

---

## Presentation Layer

The presentation layer uses MVVM. Views are passive and display state. ViewModels hold `@Published` state and delegate business operations to use cases. Neither has any knowledge of repositories or data sources.

### Feature Module Structure

Each feature is an independent Swift Package:

```
FeatureUI/
├── Sources/
│   ├── UI/              # Views and ViewModels
│   ├── Navigation/      # Feature navigation protocol
│   └── DI/              # Feature DI container
└── Tests/
```

### ViewModels

ViewModels are `@MainActor ObservableObject` classes. They receive use case protocols through initialiser injection — never concrete implementations.

**[`LoginUI/Sources/UI/LoginScreen/LoginScreenViewModel.swift`](LoginUI/Sources/UI/LoginScreen/LoginScreenViewModel.swift)**
```swift
@MainActor
public final class LoginScreenViewModel: ObservableObject {
    private let userLogin: UserLoginUseCase

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    func login() async { /* delegates to userLogin use case */ }
}
```

### Views

Views bind to `@Published` properties and delegate all actions to the ViewModel.

**[`LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift`](LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift)**
```swift
public struct LoginScreenView: View {
    @ObservedObject var viewModel: LoginScreenViewModel
    // Renders state, calls viewModel methods on user action
}
```

### Feature DI Containers

Each feature module exposes a DI container that constructs its view hierarchy. Containers that require navigation receive a navigation protocol. Containers that require domain operations receive a domain DI container.

**[`LoginUI/Sources/DI/LoginUIDI.swift`](LoginUI/Sources/DI/LoginUIDI.swift)**
```swift
public struct LoginUIDI {
    private let userDI: UserDI
    public func loginView() -> some View { /* creates LoginScreenView with ViewModel */ }
}
```

**[`HomeUI/Sources/DI/HomeUIDI.swift`](HomeUI/Sources/DI/HomeUIDI.swift)**
```swift
public struct HomeUIDI {
    private let navigation: HomeNavigation
    public func mainView() -> some View { /* creates HomeScreenView */ }
    public func detailView(id: UUID) -> some View { /* creates detail view */ }
}
```

---

## Application Layer

The application layer is the composition root — the single place where all concrete types are instantiated and wired together.

> *"In application architecture, a Composition Root is a unique location in an application where modules are composed together."*
> — Mark Seemann & Steven van Deursen, *Dependency Injection: Principles, Practices, and Patterns* (2019)
>
> *"The composition root is the only place in an application where you should use a DI container."*
> — Martin Fowler, [Inversion of Control Containers and the Dependency Injection Pattern](https://martinfowler.com/articles/injection.html) (2004)

The application layer is intentionally not unit tested — it contains no logic, only wiring.

### Dependency Injection Container

**[`iPhone/Injector.swift`](iPhone/Injector.swift)**
```swift
@MainActor
final class Injector {
    static let shared = Injector()

    let userDI: UserDI
    let navigator: Navigator
    let loginUIDI: LoginUIDI
    let homeUIDI: HomeUIDI
    let wishlistUIDI: WishlistUIDI
    let cartUIDI: CartUIDI

    // Tab views created once to preserve SwiftUI state across tab switches
    let homeView: AnyView
    let wishlistView: AnyView
    let cartView: AnyView
}
```

Tab views are instantiated once at startup and held by `Injector`. This ensures SwiftUI state — scroll position, `@State` variables, in-flight async tasks — is preserved when switching between tabs.

### Domain DI Container

**[`User/Sources/DI/UserDI.swift`](User/Sources/DI/UserDI.swift)**
```swift
public struct UserDI {
    public let userLoginUseCase: UserLoginUseCase
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase
    // Constructs session, authClient, repository, and all use cases internally
}
```

### App Entry Point

**[`iPhone/Main/Main.swift`](iPhone/Main/Main.swift)**
```swift
@main
struct Main: App {
    @StateObject private var viewModel = MainViewModel(
        observeUserLoggedIn: Injector.shared.userDI.observeUserIsLoggedInUseCase
    )

    var body: some Scene {
        WindowGroup {
            switch viewModel.path {
            case .login: Injector.shared.loginUIDI.loginView()
            case .main:  TabScreen(
                             navigator: Injector.shared.navigator,
                             homeView: Injector.shared.homeView,
                             wishlistView: Injector.shared.wishlistView,
                             cartView: Injector.shared.cartView
                         )
            }
        }
    }
}
```

---

## Navigation Architecture

Navigation is decoupled through three collaborating components: feature navigation protocols, a central `Navigator`, and a `Destination` enum.

### Feature Navigation Protocols

Each feature defines the navigation it requires as a protocol in its own module. Features have no knowledge of the `Navigator` or any other feature.

**[`HomeUI/Sources/Navigation/HomeNavigation.swift`](HomeUI/Sources/Navigation/HomeNavigation.swift)**
```swift
public protocol HomeNavigation: AnyObject {
    func openHomeDetail(id: UUID)
    func openWishlistDetail(id: UUID)
}
```

**[`WishlistUI/Sources/Navigation/WishlistNavigation.swift`](WishlistUI/Sources/Navigation/WishlistNavigation.swift)**
```swift
public protocol WishlistNavigation: AnyObject {
    func openWishlistDetail(id: UUID)
    func openCartDetail(id: UUID)
}
```

**[`CartUI/Sources/Navigation/CartNavigation.swift`](CartUI/Sources/Navigation/CartNavigation.swift)**
```swift
public protocol CartNavigation: AnyObject {
    func openCartDetail(id: UUID)
    func openHomeDetail(id: UUID)
}
```

### Navigator

`Navigator` manages tab selection and per-tab `NavigationPath`s. It conforms to all feature navigation protocols via an extension in `Destination.swift`, keeping conformance alongside the `Destination` type that it depends on.

**[`iPhone/Navigation/Navigator.swift`](iPhone/Navigation/Navigator.swift)**
```swift
@MainActor
final class Navigator: ObservableObject {
    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var cartPath = NavigationPath()

    func push(_ destination: Destination, tab: Tabs? = nil) { ... }
    func pop() { ... }
}
```

### Destination Enum

`Destination` is a `Hashable` enum centralising all route types. Its `makeView()` method delegates view construction to the appropriate UIDI container. `Navigator`'s conformance to all feature navigation protocols is declared here, co-located with the `Destination` type.

**[`iPhone/Navigation/Destination.swift`](iPhone/Navigation/Destination.swift)**
```swift
public enum Destination: Hashable {
    case homeDetail(id: UUID)
    case wishlistDetail(id: UUID)
    case cartDetail(id: UUID)

    func makeView() -> some View {
        switch self {
        case .homeDetail(let id):     Injector.shared.homeUIDI.detailView(id: id)
        case .wishlistDetail(let id): Injector.shared.wishlistUIDI.detailView(id: id)
        case .cartDetail(let id):     Injector.shared.cartUIDI.detailView(id: id)
        }
    }
}

extension Navigator: HomeNavigation, WishlistNavigation, CartNavigation {
    func openHomeDetail(id: UUID)     { push(.homeDetail(id: id)) }
    func openWishlistDetail(id: UUID) { push(.wishlistDetail(id: id)) }
    func openCartDetail(id: UUID)     { push(.cartDetail(id: id)) }
}
```

### Navigation Flow

1. User taps a button in a `View`
2. `View` calls a method on its `ViewModel`
3. `ViewModel` calls a method on its navigation protocol (e.g. `HomeNavigation`)
4. `Navigator` (which conforms to `HomeNavigation`) receives the call
5. `Navigator.push()` appends a `Destination` value to the active `NavigationPath`
6. SwiftUI's `NavigationStack` detects the path change and calls `.navigationDestination(for: Destination.self)`
7. `Destination.makeView()` constructs and returns the appropriate view via the UIDI container

---

## Testing Strategy

Each layer is independently testable:

- **Domain** — Test use cases with mock `UserRepository` implementations. No frameworks required.
- **Data** — Test `DefaultUserRepository` with mock `AuthClient` and `UserSession` implementations.
- **Presentation** — Test ViewModels with mock use case implementations.

Protocol-based design at every layer means mocking requires only a conforming struct or class — no third-party mocking libraries needed.

See test files in each module's `Tests/` directory.

---

## Module Dependencies

```
iPhone (App)
├── UserDI  ──▶  User (Domain)
│           ──▶  UserData  ──▶  User (Domain)
├── LoginUIDI  ──▶  LoginUI
│              ──▶  UserDI
├── HomeUIDI     ──▶  HomeUI
├── WishlistUIDI ──▶  WishlistUI
└── CartUIDI     ──▶  CartUI
```

---

## References

- Robert C. Martin, *Clean Architecture: A Craftsman's Guide to Software Structure and Design* (2017) — Prentice Hall
- Robert C. Martin, *Agile Software Development, Principles, Patterns, and Practices* (2002) — Prentice Hall
- Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software* (2003) — Addison-Wesley
- Martin Fowler, *Patterns of Enterprise Application Architecture* (2002) — Addison-Wesley
- Martin Fowler, [Inversion of Control Containers and the Dependency Injection Pattern](https://martinfowler.com/articles/injection.html) (2004)
- Mark Seemann & Steven van Deursen, *Dependency Injection: Principles, Practices, and Patterns* (2019) — Manning

---

## Getting Started

1. Open `CleanArchitecture.xcodeproj` in Xcode
2. Build and run the `iPhone` scheme
3. Explore the code following the layer structure above

## License

See [LICENSE](LICENSE) for details.
