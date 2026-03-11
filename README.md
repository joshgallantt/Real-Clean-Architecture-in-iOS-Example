# Clean Architecture for iOS

A practical implementation of Clean Architecture in SwiftUI, demonstrating how to structure an iOS application with clear separation of concerns, testability, and maintainability. The architecture is grounded in principles from Robert C. Martin's *Clean Architecture* (2017), Eric Evans' *Domain-Driven Design* (2003), and Martin Fowler's *Patterns of Enterprise Application Architecture* (2002).

---

## Why Architecture Matters

> *"The cost of maintaining a software system is not determined by how it was originally built, but by how easy it is to change."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 1

Every architectural decision in this project is an answer to the same underlying question: **how do we keep the cost of change low as the application grows?**

Without deliberate structure, iOS codebases tend toward a familiar failure mode: ViewModels that call URLSession directly, business rules scattered across UI handlers, and navigation logic tangled into screen transitions. The result is code that cannot be tested without a simulator, cannot be changed without reading all of it first, and cannot be extended without risking breakage in unrelated features.

The layers and patterns here are not ceremony. Each one solves a specific coupling problem.

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

**Why this matters:** If the domain layer depended on the data layer, changing your persistence mechanism would require touching business logic. If business logic lived in ViewModels, you couldn't test it without constructing a SwiftUI view. The Dependency Rule is the mechanism that makes each layer independently replaceable and testable. The direction of dependencies is the architecture.

### SOLID Principles

Robert C. Martin introduced the SOLID principles in *Agile Software Development, Principles, Patterns, and Practices* (2002). Each principle addresses a specific way that code becomes hard to change:

- **Single Responsibility** — Each class has one reason to change. `LoginScreenViewModel` manages login UI state. `DefaultUserRepository` manages user data access. When requirements change, you know exactly which file to open — and which files are safe to leave closed. Mixing concerns means a UI change requires reading infrastructure code to understand what's safe to touch.

- **Open/Closed** — Behaviour is extended through protocols, not modification. Adding a new `AuthClient` implementation requires no changes to `DefaultUserRepository`. If `DefaultUserRepository` constructed `FakeAuthClient` directly, every new auth backend would require modifying tested, working code.

- **Liskov Substitution** — `FakeAuthClient` is a drop-in replacement for any real `AuthClient`. ViewModels accept any `UserLoginUseCase`, not a concrete class. Violations of this principle mean that "replacing" a component actually requires auditing all of its callers.

- **Interface Segregation** — Navigation protocols are small and feature-scoped. `HomeNavigation` only exposes navigation relevant to the Home feature. Fat interfaces force implementations to depend on methods they don't use, creating unnecessary coupling between unrelated features.

- **Dependency Inversion** — High-level modules (`DefaultUserRepository`) depend on abstractions (`AuthClient`, `UserSession`), not concretions. This is what makes the entire testing strategy possible — every concrete dependency can be swapped for a test double at the protocol boundary.

### Separation of Concerns

> *"Gather together the things that change for the same reasons. Separate things that change for different reasons."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 7

UI changes for design reasons. Business rules change for product reasons. Data access changes for infrastructure reasons. When these are co-located, a design change requires a code archaeologist to determine which parts are safe to touch and which parts carry business logic that must not break.

Each module in this project has a single axis of change. A new screen design touches only `*UI` modules. A new business rule touches only the domain. A new backend touches only the data layer.

### Repository Pattern

> *"A Repository mediates between the domain and data mapping layers, acting like an in-memory collection of domain objects."*
> — Martin Fowler, *Patterns of Enterprise Application Architecture* (2002), Chapter 10

**Why this matters:** Without a repository abstraction, use cases call data access code directly. The moment a use case imports `URLSession` or a database framework, it can no longer be tested without that infrastructure being present. The repository protocol defines *what* the domain needs from data access. The implementation defines *how* it is satisfied. The domain never knows the difference.

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

Each feature is a separate Swift Package. This is not just organisation — it is enforcement. The Swift compiler guarantees that `HomeUI` cannot import `LoginUI` unless that dependency is declared explicitly. Architectural boundaries that rely only on convention erode over time. Module boundaries that rely on the compiler do not.

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

**Why isolate the domain?** The domain is the most valuable and most stable part of the application. Business rules change for business reasons — not because SwiftUI released a new API or the backend switched from REST to GraphQL. Keeping the domain free of framework dependencies means it survives technology changes intact. Martin calls this the *Stable Dependencies Principle*: depend in the direction of stability.

### Entities

> *"An object primarily defined by its identity is called an Entity."*
> — Eric Evans, *Domain-Driven Design* (2003), Chapter 5

Entities are the core business objects. They are framework-independent and carry no persistence or UI concerns. A `User` is a `User` regardless of how it was fetched, how it is displayed, or where it is stored.

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

Each use case protocol represents one specific business operation. Each has a name that describes what the application does — `UserLoginUseCase`, `ObserveUserIsLoggedInUseCase` — making the business capabilities of the system discoverable by reading the domain alone.

**Why use cases?** Without them, business logic leaks into ViewModels, repositories, and — eventually — views. The result is that "where does login actually happen?" has no clear answer. Use cases give business operations a home. They can be tested without UI, without a network, and without understanding the rest of the system.

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

Repository protocols are defined here in the domain layer — not in the data layer. This is the Dependency Inversion Principle applied directly: the domain defines the interface it needs, and the data layer satisfies it. The domain is not a client of the data layer; the data layer is a plugin to the domain.

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

**Why a separate data layer?** Infrastructure details are volatile. APIs change. Authentication mechanisms are replaced. Caching strategies evolve. Isolating these details behind the repository contract means none of those changes propagate inward to the domain or outward to the UI. The rest of the application continues to function against the same contract regardless of what changes underneath it.

### Repository Implementation

`DefaultUserRepository` coordinates between data sources, maps errors to domain types, and satisfies the `UserRepository` contract. Error mapping at the boundary is deliberate — domain error types must not carry infrastructure-specific codes, because the domain should not know that authentication even goes over a network.

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

### Data Sources

Data sources are also protocol-driven. `DefaultUserRepository` is tested by injecting a fake `AuthClient` and a fake `UserSession` — no network required, no simulator required.

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

`FakeAuthClient` is the default implementation — an `actor` that simulates authentication without a real backend. Swap it for any `AuthClient` conformance to connect to a real API without touching a single line of domain or presentation code.

---

## Presentation Layer

The presentation layer uses MVVM. Views are passive and display state. ViewModels hold `@Published` state and delegate business operations to use cases. Neither has any knowledge of repositories or data sources.

**Why MVVM?** SwiftUI views are value types recreated frequently by the framework. Business logic placed in a view gets destroyed with it. ViewModels are reference types that survive view recreation. More importantly: views cannot be unit tested. ViewModels can. Keeping logic in ViewModels and views purely declarative means presentation behaviour can be verified without rendering a single pixel.

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

ViewModels are `@MainActor ObservableObject` classes. They receive use case protocols through initialiser injection — never concrete implementations. A `LoginScreenViewModel` test does not need a network stack, a session, or an auth service. It needs an object that satisfies `UserLoginUseCase`.

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

Views bind to `@Published` properties and delegate all actions to the ViewModel. A view has no `if/else` business logic, no network calls, and no navigation decisions. It answers one question: given this state, what should be on screen?

**[`LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift`](LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift)**
```swift
public struct LoginScreenView: View {
    @ObservedObject var viewModel: LoginScreenViewModel
    // Renders state, calls viewModel methods on user action
}
```

### Feature DI Containers

Each feature module exposes a DI container that constructs its view hierarchy. The container accepts its dependencies through its initialiser — navigation protocols for UI features, domain DI containers for features with business operations.

**Why per-feature DI containers?** A monolithic injector that constructs every view in the app conflates the wiring of unrelated features. Per-feature containers mean each feature is responsible for constructing its own objects. The application-level `Injector` assembles the containers; the containers assemble the views.

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

**Why a composition root?** If each class constructs its own dependencies, there is no single place in the codebase that represents how the application is wired. Bugs that arise from incorrect wiring are invisible until runtime, and fixing them requires searching across the entire codebase. The composition root makes the dependency graph explicit, visible, and located in one file. It is the only place in the application that is aware of all concrete types simultaneously.

The application layer is intentionally not unit tested — it contains no logic, only wiring. Testing the wiring is what integration and UI tests are for.

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

Tab views are instantiated once at startup and held by `Injector`. If `TabScreen` called `homeUIDI.mainView()` on each render, SwiftUI would create a new view identity on every tab switch, destroying all `@State`, scroll positions, and in-flight async tasks. Holding the instances in `Injector` gives them stable identity across the lifetime of the app.

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

**Why decouple navigation?** The naive approach is to give each ViewModel a reference to a `Navigator` and have it call `navigator.push(...)` directly. This means every `*UI` feature package must import the application target to access `Navigator` — a feature module depending on the composition root, which completely inverts the dependency direction. Features would know about the application that hosts them, rather than the application knowing about features.

Navigation protocols invert this. Each feature defines what navigation capabilities it needs. The application satisfies those capabilities. Features remain ignorant of how or where they are hosted.

### Feature Navigation Protocols

Each feature defines the navigation it requires as a protocol in its own module. `HomeUI` knows it can open a home detail and a wishlist detail. It does not know that those destinations exist in separate packages, that navigation is managed by a `NavigationStack`, or that there is a `Navigator` at all.

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

`Navigator` manages tab selection and per-tab `NavigationPath`s. It conforms to all feature navigation protocols — but this conformance is declared in `Destination.swift`, co-located with the `Destination` type it depends on to do so, rather than scattered across the codebase.

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

`Destination` is a `Hashable` enum that centralises all route types. Its `makeView()` method delegates view construction to the appropriate UIDI container, keeping view creation inside the DI layer where it belongs.

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

Each layer is independently testable because every dependency is a protocol:

- **Domain** — Test use cases with mock `UserRepository` implementations. No frameworks, no simulator, no network.
- **Data** — Test `DefaultUserRepository` with mock `AuthClient` and `UserSession` implementations.
- **Presentation** — Test ViewModels with mock use case implementations.

**Why does this matter?** Tests that require a simulator run slowly and fail for infrastructure reasons unrelated to the logic being tested. Tests that depend on a real network are non-deterministic. Protocol-based design means every layer can be tested with fast, deterministic, in-process unit tests. No third-party mocking libraries are needed — a conforming struct is sufficient.

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

No feature module depends on another feature module. No domain module depends on a UI or data module. These constraints are enforced by the compiler through Swift Package Manager, not by convention.

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
