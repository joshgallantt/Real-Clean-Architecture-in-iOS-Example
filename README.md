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
├── Component/
│   ├── User/                 # Identity, session, and preferences (Swift Package)
│   │   ├── Domain/           # Entities, use cases, repository contracts
│   │   ├── Data/             # Repository implementations, local + remote data sources
│   │   └── DI/                # Dependency injection for User module
│   └── Product/               # Product catalog (Swift Package)
│       ├── Domain/           # Entities, use cases, repository contracts
│       ├── Data/               # DummyJSON-backed repository implementation
│       └── DI/                  # Dependency injection for Product module
├── UI/
│   ├── LoginUI/               # Login feature (Swift Package)
│   ├── HomeUI/                # Product catalog feature (Swift Package)
│   ├── SearchUI/              # Product search feature (Swift Package)
│   ├── WishlistUI/            # Wishlist feature (Swift Package)
│   ├── BagUI/                 # Bag (cart) feature (Swift Package)
│   └── AccountUI/             # Account: profile, log in/out, preferences (Swift Package)
├── Library/
│   └── Networking/            # Shared HTTP client, no domain dependencies (Swift Package)
└── iPhone/                   # Application layer — composition root
    ├── Injector.swift         # Wires all dependencies together
    ├── Navigation/            # Navigator and Destination
    └── Main/                  # App entry point and tab screen
```

Each feature is a separate Swift Package. This is not just organisation — it is enforcement. The Swift compiler guarantees that `HomeUI` cannot import `LoginUI` unless that dependency is declared explicitly. Architectural boundaries that rely only on convention erode over time. Module boundaries that rely on the compiler do not.

Packages are grouped by role — `Component/` for domain+data, `UI/` for presentation, `Library/` for shared infrastructure with no domain dependencies — so the folder tree reads as architecture, not an alphabetical list.

The app has five tabs: **Home** and **Search** browse the product catalog (backed by the real [DummyJSON](https://dummyjson.com) API), **Bag** and **Wishlist** are UI-only feature skeletons, and **Account** shows the signed-in profile or a guest state with a way to log in. The app supports guest use — there is no forced login gate; `Account` is simply where authentication happens.

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

**[`Component/User/Sources/Domain/Model/User.swift`](Component/User/Sources/Domain/Model/User.swift)**
```swift
public struct User: Equatable, Sendable {
    public let id: Int
    public let username: String
    public let email: String
    public let firstName: String
    public let lastName: String
}
```

**[`Component/Product/Sources/Domain/Model/Product.swift`](Component/Product/Sources/Domain/Model/Product.swift)**
```swift
public struct Product: Equatable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let description: String
    public let category: String
    public let price: Double
    // ...discountPercentage, rating, stock, brand, thumbnail, images
}
```

### Use Cases

> *"Use cases contain application-specific business rules... They orchestrate the flow of data to and from the entities."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 16

Each use case protocol represents one specific business operation. Each has a name that describes what the application does — `UserLoginUseCase`, `ObserveUserIsLoggedInUseCase` — making the business capabilities of the system discoverable by reading the domain alone.

**Why use cases?** Without them, business logic leaks into ViewModels, repositories, and — eventually — views. The result is that "where does login actually happen?" has no clear answer. Use cases give business operations a home. They can be tested without UI, without a network, and without understanding the rest of the system.

**[`Component/User/Sources/Domain/UseCases/UserLoginUseCase.swift`](Component/User/Sources/Domain/UseCases/UserLoginUseCase.swift)**
```swift
public protocol UserLoginUseCase {
    @MainActor
    func execute(username: String, password: String) async -> Result<Void, LoginError>
}
```

- `UserIsLoggedInUseCase` — synchronous check of current login state
- `ObserveUserIsLoggedInUseCase` — reactive stream of login state changes
- `GetCurrentUserUseCase` — returns the signed-in `User`, or `nil` for a guest
- `UserLogoutUseCase` — clears the session
- `GetUserPreferencesUseCase` / `SaveUserPreferencesUseCase` — read/write app preferences, guest-safe
- `GetProductsUseCase` / `SearchProductsUseCase` / `GetProductUseCase` (in `Component/Product`) — product catalog operations

### Repository Contracts

Repository protocols are defined here in the domain layer — not in the data layer. This is the Dependency Inversion Principle applied directly: the domain defines the interface it needs, and the data layer satisfies it. The domain is not a client of the data layer; the data layer is a plugin to the domain.

**[`Component/User/Sources/Domain/Repository/UserRepository.swift`](Component/User/Sources/Domain/Repository/UserRepository.swift)**
```swift
public protocol UserRepository {
    @MainActor
    var loggedInPublisher: AnyPublisher<Bool, Never> { get }
    @MainActor
    var currentUser: User? { get }
    @MainActor
    func login(username: String, password: String) async -> Result<Void, LoginError>
    @MainActor
    func logout() async
}
```

**Why does `UserPreferencesRepository` live in `Component/User` and not its own component?** The app supports guest use, so preferences must work with no `User` at all — the natural instinct is to make preferences fully independent of identity. But the *storage strategy* here is identity-aware: preferences always write to a local, guest-safe store, and additionally sync to the backend only when a session exists. That coordination — "write locally always, write remotely only if logged in" — is a concern that belongs next to the thing that knows about sessions. Splitting it into a separate component would either duplicate that session-awareness or force the two components to depend on each other. `UserPreferencesRepository` is a distinct protocol from `UserRepository` (Interface Segregation still applies within the module), but it lives in the same package because both repositories are coordinated by the same `UserSession`.

**[`Component/User/Sources/Domain/Repository/UserPreferencesRepository.swift`](Component/User/Sources/Domain/Repository/UserPreferencesRepository.swift)**
```swift
public protocol UserPreferencesRepository {
    @MainActor
    func getPreferences() async -> UserPreferences
    @MainActor
    func savePreferences(_ preferences: UserPreferences) async
}
```

---

## Data Layer

The data layer implements domain contracts and handles all external data concerns — network, session, persistence. It depends on the domain layer but the domain layer has no knowledge of it.

**Why a separate data layer?** Infrastructure details are volatile. APIs change. Authentication mechanisms are replaced. Caching strategies evolve. Isolating these details behind the repository contract means none of those changes propagate inward to the domain or outward to the UI. The rest of the application continues to function against the same contract regardless of what changes underneath it.

### Repository Implementation

`DefaultUserRepository` coordinates between data sources, maps errors to domain types, and satisfies the `UserRepository` contract. Error mapping at the boundary is deliberate — domain error types must not carry infrastructure-specific codes, because the domain should not know that authentication even goes over a network.

**[`Component/User/Sources/Data/DefaultUserRepository.swift`](Component/User/Sources/Data/DefaultUserRepository.swift)**
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

**[`Component/User/Sources/Data/Auth/AuthClient.swift`](Component/User/Sources/Data/Auth/AuthClient.swift)**
```swift
public protocol AuthClient: Sendable {
    func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
```

**[`Component/User/Sources/Data/Session/UserSession.swift`](Component/User/Sources/Data/Session/UserSession.swift)**
```swift
@MainActor
public protocol UserSession: AnyObject {
    var user: User? { get }
    var isLoggedInPublisher: AnyPublisher<Bool, Never> { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}
```

`DummyJSONAuthClient` is the default implementation — it calls the real [DummyJSON](https://dummyjson.com) `/auth/login` endpoint via `Networking`. `FakeAuthClient` still ships alongside it as an in-memory `actor` for tests and previews. Swap either for any `AuthClient` conformance without touching a single line of domain or presentation code — this is the Liskov Substitution Principle made concrete, and it is also how a real backend gets connected: no domain or presentation code changes, only the concrete type passed into `UserDI`'s initialiser.

### Guest-Safe Preferences: Local + Remote

`DefaultUserPreferencesRepository` coordinates two data sources with different guarantees: a `UserPreferencesLocalStore` (UserDefaults-backed, always available) and a `UserPreferencesRemoteStore` (DummyJSON-backed, requires a session). Reads always come from local storage — guests get the same preferences experience as signed-in users. Writes go to local storage unconditionally, then best-effort sync to the remote store only if `UserSession.user` is non-nil.

**[`Component/User/Sources/Data/Preferences/DefaultUserPreferencesRepository.swift`](Component/User/Sources/Data/Preferences/DefaultUserPreferencesRepository.swift)**
```swift
public func savePreferences(_ preferences: UserPreferences) async {
    localStore.setBool(preferences.notificationsEnabled, forKey: notificationsKey)
    guard let user = session.user else { return }   // guest: local-only, no error
    try? await remoteStore.syncPreferences(.init(notificationsEnabled: preferences.notificationsEnabled), userID: user.id)
}
```

### Shared Networking

`Library/Networking` is a dependency-free Swift Package providing `HTTPClient`, a small protocol (`get`/`post`/`patch`) with a `URLSessionHTTPClient` default implementation. It lives under `Library/` — not `Component/` — because it carries no domain knowledge at all; both `Component/User` and `Component/Product` depend on it independently, and it would exist unchanged in a completely different app.

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

**[`UI/LoginUI/Sources/UI/LoginScreen/LoginScreenViewModel.swift`](UI/LoginUI/Sources/UI/LoginScreen/LoginScreenViewModel.swift)**
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

**[`UI/LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift`](UI/LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift)**
```swift
public struct LoginScreenView: View {
    @ObservedObject var viewModel: LoginScreenViewModel
    // Renders state, calls viewModel methods on user action
}
```

### Feature DI Containers

Each feature module exposes a DI container that constructs its view hierarchy. The container accepts its dependencies through its initialiser — navigation protocols for UI features, domain DI containers for features with business operations.

**Why per-feature DI containers?** A monolithic injector that constructs every view in the app conflates the wiring of unrelated features. Per-feature containers mean each feature is responsible for constructing its own objects. The application-level `Injector` assembles the containers; the containers assemble the views.

**[`UI/LoginUI/Sources/DI/LoginUIDI.swift`](UI/LoginUI/Sources/DI/LoginUIDI.swift)**
```swift
public struct LoginUIDI {
    private let userLogin: UserLoginUseCase
    public func loginView() -> some View { /* creates LoginScreenView with ViewModel */ }
}
```

**Why a single use case, not the whole `UserDI` container?** This is the Interface Segregation Principle applied to dependency injection. `LoginUIDI` needs exactly one capability — logging a user in. Injecting the full `UserDI` container would give it visibility into `userIsLoggedInUseCase` and `observeUserIsLoggedInUseCase` too, dependencies it never calls. Fowler's dependency injection writing warns against this same shape under the name Service Locator: injecting a container that *can* resolve anything, rather than the one collaborator actually needed, blurs the boundary the DDD layering is meant to enforce. Only the application-layer `Injector` — the composition root — is allowed to hold a whole `UserDI`.

**[`UI/HomeUI/Sources/DI/HomeUIDI.swift`](UI/HomeUI/Sources/DI/HomeUIDI.swift)**
```swift
public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let getProducts: GetProductsUseCase
    private let getProduct: GetProductUseCase
    public func mainView() -> some View { /* creates HomeScreenView, lists products */ }
    public func detailView(id: Int) -> some View { /* creates detail view for a product id */ }
}
```

`HomeUI` and `SearchUI` both depend on `Component/Product`'s domain product (`import Product`), never on `ProductData` or `ProductDI` — the same UI-may-depend-on-domain rule `LoginUI` follows for `User`.

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
    let productDI: ProductDI
    let navigator: Navigator
    let loginUIDI: LoginUIDI
    let homeUIDI: HomeUIDI
    let searchUIDI: SearchUIDI
    let wishlistUIDI: WishlistUIDI
    let bagUIDI: BagUIDI
    let accountUIDI: AccountUIDI

    // Tab views created once to preserve SwiftUI state across tab switches
    let homeView: AnyView
    let searchView: AnyView
    let wishlistView: AnyView
    let bagView: AnyView
    let accountView: AnyView
    let loginView: AnyView
}
```

Tab views are instantiated once at startup and held by `Injector`. If `TabScreen` called `homeUIDI.mainView()` on each render, SwiftUI would create a new view identity on every tab switch, destroying all `@State`, scroll positions, and in-flight async tasks. Holding the instances in `Injector` gives them stable identity across the lifetime of the app.

### Domain DI Container

**[`Component/User/Sources/DI/UserDI.swift`](Component/User/Sources/DI/UserDI.swift)**
```swift
public struct UserDI {
    public let userLoginUseCase: UserLoginUseCase
    public let userLogoutUseCase: UserLogoutUseCase
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase
    public let getCurrentUserUseCase: GetCurrentUserUseCase
    public let getUserPreferencesUseCase: GetUserPreferencesUseCase
    public let saveUserPreferencesUseCase: SaveUserPreferencesUseCase
    // Constructs session, authClient, local/remote preference stores, repositories, and all use cases internally
}
```

### App Entry Point

There is no forced login gate. `Main` always shows `TabScreen`; a guest can use Home, Search, Bag, and Wishlist immediately, and signs in from the Account tab, which presents `LoginUI` as a sheet.

**[`iPhone/Main/Main.swift`](iPhone/Main/Main.swift)**
```swift
@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            TabScreen(
                navigator: Injector.shared.navigator,
                homeView: Injector.shared.homeView,
                searchView: Injector.shared.searchView,
                wishlistView: Injector.shared.wishlistView,
                bagView: Injector.shared.bagView,
                accountView: Injector.shared.accountView,
                loginView: Injector.shared.loginView
            )
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

Each feature defines the navigation it requires as a protocol in its own module. `HomeUI` knows it can open a home detail. It does not know that navigation is managed by a `NavigationStack`, or that there is a `Navigator` at all. `Home` and `Search` route on `Int` product ids since they're backed by the real product catalog; `Wishlist` and `Bag` stay on placeholder `UUID` ids since they remain UI-only skeletons.

**[`UI/HomeUI/Sources/Navigation/HomeNavigation.swift`](UI/HomeUI/Sources/Navigation/HomeNavigation.swift)**
```swift
public protocol HomeNavigation: AnyObject {
    func openHomeDetail(id: Int)
}
```

**[`UI/SearchUI/Sources/Navigation/SearchNavigation.swift`](UI/SearchUI/Sources/Navigation/SearchNavigation.swift)**
```swift
public protocol SearchNavigation: AnyObject {
    func openSearchDetail(id: Int)
}
```

**[`UI/WishlistUI/Sources/Navigation/WishlistNavigation.swift`](UI/WishlistUI/Sources/Navigation/WishlistNavigation.swift)**
```swift
public protocol WishlistNavigation: AnyObject {
    func openWishlistDetail(id: UUID)
    func openBagDetail(id: UUID)
}
```

**[`UI/BagUI/Sources/Navigation/BagNavigation.swift`](UI/BagUI/Sources/Navigation/BagNavigation.swift)**
```swift
public protocol BagNavigation: AnyObject {
    func openBagDetail(id: UUID)
}
```

**[`UI/AccountUI/Sources/Navigation/AccountNavigation.swift`](UI/AccountUI/Sources/Navigation/AccountNavigation.swift)**
```swift
public protocol AccountNavigation: AnyObject {
    func openLogin()
    func dismissLogin()
}
```

`AccountNavigation` doesn't push a `Destination` at all — logging in is presented modally, not pushed onto a tab's stack. `Navigator.isPresentingLogin` backs a `.sheet` at the `TabScreen` level, and `AccountScreenViewModel` calls `dismissLogin()` once it observes the session becoming authenticated.

### Navigator

`Navigator` manages tab selection and per-tab `NavigationPath`s. It conforms to all feature navigation protocols — but this conformance is declared in `Destination.swift`, co-located with the `Destination` type it depends on to do so, rather than scattered across the codebase.

**[`iPhone/Navigation/Navigator.swift`](iPhone/Navigation/Navigator.swift)**
```swift
@MainActor
final class Navigator: ObservableObject {
    enum Tabs: Hashable { case home, search, bag, wishlist, account }

    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var bagPath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var isPresentingLogin = false

    func push(_ destination: Destination, tab: Tabs? = nil) { ... }
    func pop() { ... }
}
```

`Account` has no `NavigationPath` of its own — it's a single screen with no push destinations, so it's excluded from the `push`/`pop` switch entirely rather than carrying dead cases.

### Destination Enum

`Destination` is a `Hashable` enum that centralises all route types. Its `makeView()` method delegates view construction to the appropriate UIDI container, keeping view creation inside the DI layer where it belongs.

**[`iPhone/Navigation/Destination.swift`](iPhone/Navigation/Destination.swift)**
```swift
public enum Destination: Hashable {
    case homeDetail(id: Int)
    case searchDetail(id: Int)
    case wishlistDetail(id: UUID)
    case bagDetail(id: UUID)

    func makeView() -> some View {
        switch self {
        case .homeDetail(let id):     Injector.shared.homeUIDI.detailView(id: id)
        case .searchDetail(let id):   Injector.shared.searchUIDI.detailView(id: id)
        case .wishlistDetail(let id): Injector.shared.wishlistUIDI.detailView(id: id)
        case .bagDetail(let id):      Injector.shared.bagUIDI.detailView(id: id)
        }
    }
}

extension Navigator: HomeNavigation, SearchNavigation, WishlistNavigation, BagNavigation, AccountNavigation {
    func openHomeDetail(id: Int)      { push(.homeDetail(id: id)) }
    func openSearchDetail(id: Int)    { push(.searchDetail(id: id)) }
    func openWishlistDetail(id: UUID) { push(.wishlistDetail(id: id)) }
    func openBagDetail(id: UUID)      { push(.bagDetail(id: id)) }
    func openLogin()                  { isPresentingLogin = true }
    func dismissLogin()               { isPresentingLogin = false }
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
├── UserDI     ──▶  User (Domain)
│              ──▶  UserData  ──▶  User (Domain), Networking
├── ProductDI  ──▶  Product (Domain)
│              ──▶  ProductData  ──▶  Product (Domain), Networking
├── LoginUIDI    ──▶  LoginUI  ──▶  User (Domain)
├── HomeUIDI     ──▶  HomeUI   ──▶  Product (Domain)
├── SearchUIDI   ──▶  SearchUI ──▶  Product (Domain)
├── WishlistUIDI ──▶  WishlistUI
├── BagUIDI      ──▶  BagUI
└── AccountUIDI  ──▶  AccountUI ──▶  User (Domain)
```

No feature module depends on another feature module. No domain module depends on a UI or data module. `Networking` is the one package with no dependents pointing at it from Domain — it's shared infrastructure, sitting under `Library/` rather than `Component/`, and both `User` and `Product`'s data layers depend on it independently rather than on each other. These constraints are enforced by the compiler through Swift Package Manager, not by convention.

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
3. Home and Search work immediately as a guest, against the real [DummyJSON](https://dummyjson.com) product catalog
4. To sign in from the Account tab, use any of [DummyJSON's demo accounts](https://dummyjson.com/users) — e.g. username `emilys`, password `emilyspass`
5. Explore the code following the layer structure above

## License

See [LICENSE](LICENSE) for details.
