# Clean Architecture for iOS

A practical implementation of Clean Architecture in SwiftUI, demonstrating how to structure an iOS application with clear separation of concerns, testability, and maintainability. The architecture is grounded in principles from Robert C. Martin's *Clean Architecture* (2017), Eric Evans' *Domain-Driven Design* (2003), and Martin Fowler's *Patterns of Enterprise Application Architecture* (2002).

---

## Why Architecture Matters

> *"The goal of software architecture is to minimize the human resources required to build and maintain the required system."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 1

Every architectural decision in this project is an answer to the same underlying question: **how do we keep the cost of change low as the application grows?**

Without deliberate structure, iOS codebases tend toward a familiar failure mode: ViewModels that call URLSession directly, business rules scattered across UI handlers, and navigation logic tangled into screen transitions. The result is code that cannot be tested without a simulator, cannot be changed without reading all of it first, and cannot be extended without risking breakage in unrelated features.

The layers and patterns here are not ceremony. Each one solves a specific coupling problem.

---

## Architecture Principles

### The Dependency Rule

> *"Source code dependencies must point only inward, toward higher-level policies."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 22

Dependencies point inward. The domain layer knows nothing about the data or presentation layers. The data layer knows about the domain but not the UI. The presentation layer depends on the domain but not on any specific data source.

```
Presentation ──▶ Domain ◀── Data
     └──────────────────────────▶ (never)
```

**Why this matters:** If the domain layer depended on the data layer, changing your persistence mechanism would require touching business logic. If business logic lived in ViewModels, you couldn't test it without constructing a SwiftUI view. The Dependency Rule is the mechanism that makes each layer independently replaceable and testable. The direction of dependencies is the architecture.

### SOLID Principles

Robert C. Martin collected the five principles that Michael Feathers later named SOLID in *Agile Software Development, Principles, Patterns, and Practices* (2002), and revisits each of them in *Clean Architecture* (2017), Chapters 7–11. Each principle addresses a specific way that code becomes hard to change:

- **Single Responsibility** — Each type has one reason to change. `AuthViewModel` manages the state of one authentication sheet. `DefaultSessionRepository` manages session data access. When requirements change, you know exactly which file to open — and which files are safe to leave closed.

- **Open/Closed** — Behaviour is extended through protocols, not modification. Adding a new `AuthClient` implementation requires no changes to `DefaultSessionRepository`. If the repository constructed `FakeAuthClient` directly, every new auth backend would require modifying tested, working code.

- **Liskov Substitution** — `FakeAuthClient` is a drop-in replacement for any real `AuthClient`. ViewModels accept any `LoginUseCase`, not a concrete type. Violations of this principle mean that "replacing" a component actually requires auditing all of its callers.

- **Interface Segregation** — Navigation protocols and presentation ports are small and feature-scoped. `SnackbarPresenting` has exactly one method: a feature says what happened and has no say in how long it shows or how it goes away. Fat interfaces force implementations to depend on methods they don't use.

- **Dependency Inversion** — High-level modules (`DefaultSessionRepository`) depend on abstractions (`AuthClient`, `SessionStore`), not concretions. This is what makes the entire testing strategy possible — every concrete dependency can be swapped for a test double at the protocol boundary.

### Separation of Concerns

> *"Gather into components those classes that change for the same reasons and at the same times. Separate into different components those classes that change at different times and for different reasons."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 13 — the Common Closure Principle

UI changes for design reasons. Business rules change for product reasons. Data access changes for infrastructure reasons. When these are co-located, a design change requires a code archaeologist to determine which parts are safe to touch and which parts carry business logic that must not break.

Each module in this project has a single axis of change. A new screen design touches only `*UI` modules. A new business rule touches only the domain. A new backend touches only the data layer.

### Repository Pattern

> *"Mediates between the domain and data mapping layers using a collection-like interface for accessing domain objects."*
> — Martin Fowler, *Patterns of Enterprise Application Architecture* (2002), Chapter 13

**Why this matters:** Without a repository abstraction, use cases call data access code directly. The moment a use case imports `URLSession` or `UserDefaults`, it can no longer be tested without that infrastructure being present. The repository protocol defines *what* the domain needs from data access. The implementation defines *how* it is satisfied. The domain never knows the difference.

---

## Project Structure

```
├── Component/                  # Domain + Data packages
│   ├── Session/                # Identity, authentication, session lifetime
│   ├── Product/                # Product catalog (DummyJSON-backed)
│   ├── SearchHistory/          # Per-user recent search history
│   ├── Wishlist/               # Per-user wishlist, gated on authentication
│   ├── Bag/                    # Per-shopper bag, and the notices the shop leaves on it
│   ├── Order/                  # What a shopper bought, for how much, and when
│   └── StockAlert/             # Who asked to be told when something is back
├── UI/                         # Presentation packages
│   ├── HomeUI/                 # Home tab
│   ├── SearchUI/               # Search tab: categories, suggestions, results
│   ├── WishlistUI/             # Wishlist tab
│   ├── BagUI/                  # Bag tab
│   ├── AccountUI/              # Account tab: profile, log in/out
│   ├── ProductUI/              # Shared product UI: card, grid, details screen
│   ├── ProductActionsUI/       # What a shopper can do to a product: save, buy, be told
│   ├── OrderUI/                # Buy Now, checking out, confirmation, order history
│   ├── OnboardingUI/           # First-run onboarding
│   ├── AuthUI/                 # Authentication flow, exposed as a port
│   ├── SheetUI/                # Generic sheet presentation primitive
│   └── SnackbarUI/             # Transient notifications with Undo/Retry/View
├── Library/
│   ├── Networking/             # Shared HTTP client, no domain dependencies
│   └── Money/                  # Exact amounts with their currency, no domain dependencies
└── iPhone/                     # Application layer — composition root
    ├── Composition/            # CompositionRoot + its three assemblers, Catalog, and the demo's second root
    ├── Navigation/             # Navigator + Destination
    └── Main/                   # App entry point, phases, tab screen
```

Every one of those directories is a separate Swift Package. This is not just organisation — it is enforcement. The Swift compiler guarantees that `HomeUI` cannot import `WishlistUI` unless that dependency is declared explicitly. Architectural boundaries that rely only on convention erode over time. Module boundaries that rely on the compiler do not.

Packages are grouped by role — `Component/` for domain+data, `UI/` for presentation, `Library/` for shared infrastructure with no domain dependencies — so the folder tree reads as architecture, not an alphabetical list.

The app has five tabs. **Home** and **Search** browse the real [DummyJSON](https://dummyjson.com) product catalog. **Wishlist** requires an account. **Bag** works for guests too, and tells the shopper what the shop changed while they were away. **Account** shows the signed-in profile or a guest state. The app supports guest use throughout — authentication is asked for at the moment it is actually needed, not as a gate at launch.

---

## Architecture Layers

```
┌──────────────────────────────────────────┐
│          Application Layer               │  Composition root, in three
│  iPhone/ CompositionRoot — Data, Domain  │  phases. Wires all dependencies
│  and Presentation assemblers, Navigator  │  and chooses every concrete
│                                          │  type. Pure wiring.
├──────────────────────────────────────────┤
│          Presentation Layer              │  MVVM. Views are passive.
│       *UI feature modules                │  ViewModels hold UI state and
│       Views + ViewModels + DI            │  delegate to use cases.
├──────────────────────────────────────────┤
│           Domain Layer                   │  Pure Swift. Zero framework
│       Session, Product, SearchHistory,   │  dependencies. The stable core
│       Wishlist, Bag — entities, use      │  of the application.
│       cases, repository contracts        │
├──────────────────────────────────────────┤
│            Data Layer                    │  Implements domain contracts.
│       *Data — repositories, clients,     │  Knows about networking,
│       stores, DTOs                       │  persistence, and hashing.
└──────────────────────────────────────────┘
```

---

## Domain Layer

The domain layer contains pure business logic with **zero dependencies** on external frameworks, UI, or data sources. It can be compiled, tested, and reasoned about in isolation.

**Why isolate the domain?** The domain is the most valuable and most stable part of the application. Business rules change for business reasons — not because SwiftUI released a new API or the backend switched from REST to GraphQL. Keeping the domain free of framework dependencies means it survives technology changes intact. Martin calls this the *Stable Dependencies Principle*: depend in the direction of stability.

### Entities

> *"An object defined primarily by its identity is called an ENTITY."*
> — Eric Evans, *Domain-Driven Design* (2003), Chapter 5

Entities are the core business objects. They are immutable, framework-independent, and carry no persistence or UI concerns. A `User` is a `User` regardless of how it was fetched, how it is displayed, or where it is stored.

**[`Component/Session/Sources/Domain/Model/User.swift`](Component/Session/Sources/Domain/Model/User.swift)**
```swift
public struct User: Equatable, Sendable, Identifiable {
    public let id: UserID
    public let email: Email
    public let name: PersonName
}
```

Every field is a type rather than a `String` or an `Int`. `UserID` cannot be passed where a
`ProductID` was meant. `Email` has been past the rule about what an address is, which a
`String` has not. `PersonName` says out loud that a last name is optional — plenty of people
have one name — instead of leaving that intent in a test.

Authentication state is modelled as a sum type rather than an optional user plus a boolean flag — the two-field version admits states that cannot exist ("logged in, no user"), and the enum does not.

**[`Component/Session/Sources/Domain/Model/Session.swift`](Component/Session/Sources/Domain/Model/Session.swift)**
```swift
public enum Session: Equatable, Sendable {
    case guest
    case authenticated(User)

    public var user: User? { ... }
    public var isLoggedIn: Bool { ... }
}
```

`CategoryID` and `ProductID` are similarly deliberate: a raw `String` category is
interchangeable with a title, a search term, or a product name, and a raw `Int` product id is
interchangeable with a user id or a quantity. The compiler cannot tell you when those get
crossed. Wrapping them removes a whole class of bug — and identity is the one part of another
aggregate a context may safely hold, which is exactly why it is worth a type.

**[`Component/Product/Sources/Domain/Model/Product.swift`](Component/Product/Sources/Domain/Model/Product.swift)**
```swift
public struct Product: Equatable, Hashable, Sendable, Identifiable {
    public let id: ProductID
    public let title: String
    public let description: String
    public let category: CategoryID
    public let price: Money
    public let availability: Availability
    // ...rating, brand, thumbnail, images
}
```

`price` is `Money`, not `Double`. A price like 9.99 has no exact binary representation, so
totals built by adding them drift and two amounts that should be equal compare unequal —
which matters beyond tidiness here, because whether a shopper is *told* a price moved is
decided by comparing two amounts. `Money` counts whole minor units and carries its currency.

`availability` is one idea, not a stock count plus a will-it-return flag. The flag is only
meaningful when the count is zero, so every caller has to know that to read either, and
callers end up rebuilding the same three states in their own way:

```swift
public enum Availability: Equatable, Hashable, Sendable {
    case inStock(remaining: Int)
    case outOfStock      // the shop expects to have it again
    case discontinued    // the shop is not selling it any more
}
```

### Use Cases

> *"The software in this layer contains application-specific business rules... These use cases orchestrate the flow of data to and from the entities."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 22

Each use case is a protocol naming one business operation, plus a `Default*` struct implementing it. Both live in the domain. The protocol is what callers depend on; the struct is what the DI container constructs.

Use cases are invoked through `callAsFunction`, so a call site reads as the operation itself — `await login(email:password:)`, `await addProductToWishlist(productId:)` — rather than as bureaucracy (`loginUseCase.execute(...)`).

**Why use cases?** Without them, business logic leaks into ViewModels, repositories, and — eventually — views. The result is that "where does login actually happen?" has no clear answer. Use cases give business operations a home. They can be tested without UI, without a network, and without understanding the rest of the system.

**[`Component/Session/Sources/Domain/UseCases/LoginUseCase.swift`](Component/Session/Sources/Domain/UseCases/LoginUseCase.swift)**
```swift
public protocol LoginUseCase: Sendable {
    func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError>
}

public struct DefaultLoginUseCase: LoginUseCase {
    private let sessionRepository: SessionRepository

    public func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError> {
        guard email.isValid else { return .failure(.invalidEmail) }
        guard password.isValid else { return .failure(.invalidPassword) }
        return await sessionRepository.login(email: email, password: password)
    }
}
```

Note where the validation lives. "That is not an email address" is a business rule, not a UI concern — so it is enforced in the use case, once, and every caller inherits it. The use case decides only the *order* to ask in; what counts as a valid address is `Email`'s own rule, and what counts as a valid password is `Password`'s. The login sheet renders the resulting error; it does not decide what an error is.

The full vocabulary of the application is discoverable by reading the domain alone:

| Component | Use cases |
| --- | --- |
| `Session` | `LoginUseCase`, `CreateAccountUseCase`, `LogoutUseCase`, `GetSessionUseCase`, `ObserveSessionUseCase` |
| `Product` | `BrowseCatalogUseCase`, `ViewProductUseCase`, `LookUpProductsUseCase`, `BrowseCategoriesUseCase` |
| `SearchHistory` | `GetSearchHistoryUseCase`, `RecordSearchUseCase`, `ClearSearchHistoryUseCase` |
| `Wishlist` | `ObserveWishlistUseCase`, `ObserveProductIsWishlistedUseCase`, `AddProductToWishlistUseCase`, `RemoveProductFromWishlistUseCase` |
| `Bag` | `ObserveBagUseCase`, `ObserveNoticesUseCase`, `ObserveBagItemQuantityUseCase`, `AddItemToBagUseCase`, `SetBagItemQuantityUseCase`, `BringBagUpToDateUseCase`, `AcknowledgeNoticesUseCase` |
| `Order` | `PlaceOrderUseCase`, `ObserveOrdersUseCase` |

Each name is something a shopper is trying to do. That is the test a use case name has to
pass: `LookUpProductsUseCase` describes filling in the things on a list the shopper already
has; `getProductsByIds` would only describe the query it happens to need. When the use case
layer is named after the repository's methods, the layer whose job is to enumerate the
application's intentions ends up enumerating its data access instead.

### Use Cases Composing Use Cases

`Wishlist`'s domain depends on `Session`'s domain, and that dependency is the point. Requiring an account to save a wishlist item is a business rule, so it is enforced in the domain — not by a view remembering to check first.

**[`Component/Wishlist/Sources/Domain/UseCases/AddProductToWishlistUseCase.swift`](Component/Wishlist/Sources/Domain/UseCases/AddProductToWishlistUseCase.swift)**
```swift
public struct DefaultAddProductToWishlistUseCase: AddProductToWishlistUseCase {
    private let repository: WishlistRepository
    private let getSession: GetSessionUseCase

    @MainActor
    public func callAsFunction(productId: ProductID) async -> Result<Void, WishlistError> {
        guard getSession().isLoggedIn else { return .failure(.unauthenticated) }
        repository.save(repository.wishlist.adding(WishlistItem(productId: productId)))
        return .success(())
    }
}
```

`.unauthenticated` is a domain outcome. The UI's job is to *react* to it — see [Authentication as a Domain Outcome](#authentication-as-a-domain-outcome) — not to predict it. A new caller of this use case cannot forget the rule, because it is not their rule to remember.

### Repository Contracts

Repository protocols are defined in the domain layer — not in the data layer. This is the Dependency Inversion Principle applied directly: the domain defines the interface it needs, and the data layer satisfies it. The domain is not a client of the data layer; the data layer is a plugin to the domain.

**[`Component/Session/Sources/Domain/Repository/SessionRepository.swift`](Component/Session/Sources/Domain/Repository/SessionRepository.swift)**
```swift
public protocol SessionRepository: Sendable {
    @MainActor var sessionPublisher: AnyPublisher<Session, Never> { get }
    @MainActor var currentSession: Session { get }

    func login(email: Email, password: Password) async -> Result<Void, LoginError>
    func createAccount(name: PersonName, email: Email, password: Password) async -> Result<Void, CreateAccountError>
    func logout() async
}
```

**Why is `SearchHistory` a separate component from `Product`?** Search history and the product catalog change for entirely different reasons and have entirely different storage: recent searches are per-user, local, and disposable; the catalog is remote and shared. Merging them would put a `UserDefaults`-backed concern and a network-backed concern behind one contract. `SearchHistory` depends on `Session` because history is scoped per user, and on `Product` only for `SearchTerm` — what counts as a search, and when two searches are the same search, is one rule and lives in one place.

---

## Data Layer

The data layer implements domain contracts and handles all external concerns — network, persistence, hashing, token lifetime. It depends on the domain layer; the domain layer has no knowledge of it.

**Why a separate data layer?** Infrastructure details are volatile. APIs change. Authentication mechanisms are replaced. Caching strategies evolve. Isolating these details behind the repository contract means none of those changes propagate inward to the domain or outward to the UI.

### Repository Implementation

`DefaultSessionRepository` coordinates data sources, maps infrastructure errors to domain error types, and satisfies the `SessionRepository` contract. Error mapping at the boundary is deliberate — domain error types must not carry infrastructure-specific codes, because the domain should not know that authentication involves a client at all.

**[`Component/Session/Sources/Data/DefaultSessionRepository.swift`](Component/Session/Sources/Data/DefaultSessionRepository.swift)**
```swift
public struct DefaultSessionRepository: SessionRepository {
    private let sessionStore: SessionStore
    private let authClient: AuthClient

    public func login(email: Email, password: Password) async -> Result<Void, LoginError> {
        switch await authClient.login(email: email, password: password) {
        case let .success((user, token)):
            await sessionStore.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(Self.loginError(from: error))
        }
    }
}
```

`AuthClientError.emailAlreadyInUse` maps to `CreateAccountError.emailAlreadyInUse` on the create-account path and collapses to `.unavailable` on the login path. The mapping is per-operation because the meaningful failures differ per operation — a single shared error enum would force every caller to handle cases that cannot occur.

### Data Sources

Data sources are protocol-driven. `DefaultSessionRepository` is tested by injecting a fake `AuthClient` and a fake `SessionStore` — no network, no simulator, no `UserDefaults`.

**[`Component/Session/Sources/Data/Auth/AuthClient.swift`](Component/Session/Sources/Data/Auth/AuthClient.swift)**
```swift
public protocol AuthClient: Sendable {
    func login(email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError>
    func createAccount(name: PersonName, email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
```

`FakeAuthClient` is the implementation the app currently ships: accounts are registered on-device in a `UserStore`, passwords are stored as SHA-256 hashes, and tokens are minted locally with a deterministic user id derived from the email so the same account always maps back to the same wishlist. Swapping it for a real backend means writing one new `AuthClient` conformance and changing one line in the composition root — no domain, presentation, or navigation code moves. That is the Liskov Substitution Principle paying for itself.

### Session Lifetime Is a Data Concern

**[`Component/Session/Sources/Data/Session/SessionStore.swift`](Component/Session/Sources/Data/Session/SessionStore.swift)**
```swift
@MainActor
public protocol SessionStore: AnyObject, Sendable {
    var session: Session { get }
    var sessionPublisher: AnyPublisher<Session, Never> { get }
    var authToken: AuthToken? { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}
```

`DefaultSessionStore` restores a persisted session on launch if its token is still valid, drops it if not, and schedules a task to clear the session at the exact moment the token expires. Every observer of `sessionPublisher` — the wishlist repository, the account screen, the app's root phase — reacts to expiry automatically. None of them contain a line of expiry logic. The rule lives in one place, and everything downstream is a consequence.

### User-Scoped Storage

`Bag`, `Wishlist` and `SearchHistory` each persist per shopper. What they are keyed *by* is a type,
not a string: a repeated `"guest"` literal has to be spelled the same way in every feature that
builds one, and nothing keeps those spellings honest.

**[`Component/Session/Sources/Domain/Model/Owner.swift`](Component/Session/Sources/Domain/Model/Owner.swift)**
```swift
public enum Owner: Equatable, Hashable, Sendable {
    case guest
    case signedIn(UserID)

    public init(_ session: Session) { ... }
}
```

A guest has a real bag and a real search history — that is the whole point of letting someone shop
before signing in — so being nobody in particular is one of the cases rather than the absence of
one. It lives in `Session` because identity is what `Session` is for, and because one definition
shared by two contexts is Evans' Shared Kernel, where two definitions would be two answers.

A wishlist is the exception, and deliberately so: a guest cannot save anything, so its owner is a
`UserID?` and the guest case does not exist to be handled. It differs because the rule differs.

**[`Component/Bag/Sources/Data/DefaultBagRepository.swift`](Component/Bag/Sources/Data/DefaultBagRepository.swift)**
```swift
private func switchOwner(to owner: Owner) {
    guard owner != self.owner else { return }
    self.owner = owner
    let kept = store.getBag(for: owner)
    bagSubject.value = kept.bag
    changesSubject.value = kept.changes
}
```

Note what the repository is *given*: an owner and a stream of owners — not a `Session`, and not
a session use case. It needs to know whose bag is live, not to understand identity. `BagDI`
performs that translation once at the wiring boundary, and what a bag is *filed under* is the
storage layer's business — the only place an owner turns back into a string is the code that
picks a filename.

`DefaultWishlistRepository` and `DefaultSearchHistoryRepository` take the same shape, for the same
reason. All three are handed who they are keeping something for; none of them can reach a session
to ask.

### DTOs

DTOs live in the data layer and never leak inward. `ProductDTO`, `ProductCategoryDTO`, `WishlistItemDTO`, `BagDTO`, `BagItemDTO`, `NoticeDTO`, `OrderDTO`, `OrderLineDTO`, `SessionSnapshotDTO`, and `StoredUser` are the `Codable` types; each maps to a domain model at the repository boundary. Domain models carry no `Codable` conformance at all — serialisation is a storage detail, and making entities `Codable` silently couples the domain's shape to a wire format.

### Shared Networking

`Library/Networking` is a dependency-free Swift Package providing `HTTPClient`, a small protocol with a `URLSessionHTTPClient` default implementation that maps transport, status, and decoding failures onto `HTTPClientError`.

**[`Library/Networking/Sources/Networking/HTTPClient.swift`](Library/Networking/Sources/Networking/HTTPClient.swift)**
```swift
public protocol HTTPClient: Sendable {
    func get<T: Decodable>(_ url: URL) async throws -> T
    func post<Body: Encodable, T: Decodable>(_ url: URL, body: Body) async throws -> T
}
```

It lives under `Library/` — not `Component/` — because it carries no domain knowledge at all. It would exist unchanged in a completely different app.

---

## Presentation Layer

The presentation layer uses MVVM. Views are passive and display state. ViewModels hold `@Published` state and delegate business operations to use cases. Neither has any knowledge of repositories or data sources.

**Why MVVM?** SwiftUI views are value types recreated frequently by the framework. Business logic placed in a view gets destroyed with it. ViewModels are reference types that survive view recreation. More importantly: views cannot be unit tested. ViewModels can. Keeping logic in ViewModels and views purely declarative means presentation behaviour can be verified without rendering a single pixel.

### Feature Module Structure

Most feature packages follow this layout:

```
FeatureUI/
├── Sources/
│   ├── UI/              # Views and ViewModels
│   ├── Navigation/      # Feature navigation protocol
│   └── DI/              # Feature DI container
└── Tests/
```

### ViewModels

ViewModels are `@MainActor ObservableObject` classes receiving **use case protocols** through initialiser injection — never repositories, stores, or data sources. An `AuthViewModel` test needs no network stack and no session; it needs an object that satisfies `LoginUseCase`.

**[`UI/AuthUI/Sources/AuthUIHost/AuthViewModel.swift`](UI/AuthUI/Sources/AuthUIHost/AuthViewModel.swift)**
```swift
@MainActor
final class AuthViewModel: ObservableObject {
    private let loginUseCase: LoginUseCase
    private let onAuthenticated: () -> Void

    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?

    func logIn() async {
        switch await loginUseCase(email: Email(email), password: Password(password)) {
        case .success: onAuthenticated()
        case .failure(let failure): error = AuthenticationErrorMessages.message(for: failure)
        }
    }
}
```

The raw text a person types becomes an `Email` and a `Password` here, at the edge — that is the only place a loose string is allowed, and the types are deliberately lenient so a half-typed address is still representable while it is being typed. `AuthenticationErrorMessages` lives inside `AuthUI` — the domain says *what* failed, presentation decides *how to say it*. Copy changes never touch `Session`.

It is a type of its own rather than an extension on `LoginError`, and that is deliberate: `LoginError` is declared in another module, and behaviour bolted onto it from here would not be visible to anyone reading it. Extensions that reach across a module boundary hide a type's real surface area from the file that declares it. The rule this codebase follows is that an extension may only sit beside the type it extends — every one outside a test does.

### Views

Views bind to `@Published` properties and delegate all actions to the ViewModel. A view has no business branching, no network calls, and no navigation decisions. It answers one question: given this state, what should be on screen?

### Shared UI Components

`ProductUI` is a UI package with no tab of its own. It owns the product card, the paginating product grid, and the product details screen — the things `SearchUI` and `WishlistUI` both need and neither should own. Its views take an `accessory` closure so a host feature can slot in, say, a wishlist button without `ProductUI` learning what a wishlist is.

`ProductActionsUI` is the same idea one level down, and it is named for what it *is* rather than for who uses it. It holds the three things a shopper can do to a product — save it, buy it, be told when it is back — and the decision of which to offer for a given availability.

They are not feature buttons that happen to be reused. A heart belongs to the product, not to the wishlist feature, and the set of them changes for exactly one reason: when what a shopper can do with a product changes. That is a single axis of change, which is the test for what belongs together.

There is a mechanical reason too. `BagUI` renders the heart, in the removed-items list; `WishlistUI` renders the bag button, on every row. If each button lived in its own feature's package that is a cycle, and SwiftPM refuses to build it.

A package named `SharedUI` would invite the opposite question — a name describing a *relationship* to other packages gives no criterion for what belongs inside, so eventually everything does. Named for the concept, the rule writes itself: if it is not something a shopper can do to a product, it does not go here.

**Cross-feature UI dependencies are allowed and intentional.** `SearchUI` imports `ProductUI`; `WishlistUI` imports `ProductUI`, `ProductActionsUI` and `AuthUI`. What is not allowed is a UI package importing another component's *data* layer.

### Feature DI Containers

Each feature module exposes a DI container that constructs its view hierarchy. The container accepts its dependencies through its initialiser — navigation protocols, presentation ports, and individual use cases.

**Why per-feature DI containers?** A monolithic injector that constructs every view in the app conflates the wiring of unrelated features. Per-feature containers mean each feature constructs its own objects. The application-level `CompositionRoot` assembles the containers; the containers assemble the views.

**[`UI/HomeUI/Sources/DI/HomeUIDI.swift`](UI/HomeUI/Sources/DI/HomeUIDI.swift)**
```swift
public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let browseCatalog: BrowseCatalogUseCase
    private let snackbar: SnackbarPresenting

    @MainActor
    public func mainView() -> some View { /* HomeScreenView + HomeScreenViewModel */ }
}
```

**Why individual use cases, not the whole `ProductDI` container?** This is the Interface Segregation Principle applied to dependency injection. `HomeUIDI` needs exactly one capability — listing products. Injecting the full `ProductDI` would give it visibility into `getProductUseCase` and `getCategoriesUseCase` too, dependencies it never calls. Fowler warns against this shape under the name Service Locator: injecting a container that *can* resolve anything, rather than the collaborator actually needed, blurs the boundary the layering is meant to enforce. Only the composition root holds whole component containers.

The exception is one UI container injecting another — `SearchUIDI` takes `WishlistUIDI` so search results can render wishlist buttons. That is a view-construction dependency between peers, not a reach into a component's domain wiring.

---

## Ports and Hosts: Cross-Cutting UI

Three UI concerns — sheets, snackbars, and authentication — are needed by features that must not know how any of them are implemented. Each is a package split into a **port** and a **host**:

```
SnackbarUI/
├── Sources/
│   ├── SnackbarUI/       # product `SnackbarUI`   — the port: protocol + value types
│   ├── SnackbarUIHost/   # the SwiftUI implementation
│   └── SnackbarUIDI/     # the container that constructs it
└── product `SnackbarUIDI` = SnackbarUIHost + SnackbarUIDI
```

**Features link the port. Only the composition root links the host.** `HomeUI` depends on `SnackbarUI` and can call `show(_:)`; it cannot see `SnackbarPresenter`, `SnackbarView`, or the `.snackbarHost(_:)` modifier, because those are in a product it does not link. The boundary is enforced by SwiftPM, not by discipline.

### SheetUI — the primitive

**[`UI/SheetUI/Sources/SheetUI/SheetPresenting.swift`](UI/SheetUI/Sources/SheetUI/SheetPresenting.swift)**
```swift
@MainActor
public protocol SheetPresenting: AnyObject {
    func present<Content: View>(onDismiss: (() -> Void)?, @ViewBuilder content: () -> Content)
    func dismiss()
}
```

`SheetPresenter` guarantees only one sheet is on screen at a time. Presenting while something is already up queues the successor and lets the current one finish dismissing, so SwiftUI sees a clean dismiss/present pair. Crucially, `onDismiss` fires *only* when the user ends the sheet — not when a chained sheet supersedes it, and not on a programmatic `dismiss()`. That distinction is what makes an outcome-carrying flow possible on top of it.

### SnackbarUI — one method, on purpose

**[`UI/SnackbarUI/Sources/SnackbarUI/Snackbar.swift`](UI/SnackbarUI/Sources/SnackbarUI/Snackbar.swift)**
```swift
public struct Snackbar {
    public let title: String
    public let message: String
    public let icon: String?
    public let action: SnackbarAction?

    public var displayDuration: Duration {
        .seconds(3)
    }
}
```

`displayDuration` belongs to the snackbar, not to whatever is displaying it — how long something stays up is a property of the message, and a host that decided it would have to know what each message meant. Actions are supplied by the caller — `.undo` carries the inverse operation, `.retry` re-invokes the failed one, `.view` goes to the thing — so `SnackbarUI` never learns what a wishlist or a bag is.

### AuthUI — a flow behind a single call

**[`UI/AuthUI/Sources/AuthUI/AuthPresenting.swift`](UI/AuthUI/Sources/AuthUI/AuthPresenting.swift)**
```swift
@MainActor
public protocol AuthPresenting: AnyObject {
    /// - Returns: `true` if the user is authenticated — they already were, or they just
    ///   completed the flow. `false` if they dismissed it first.
    @discardableResult
    func show(_ prompt: AuthenticationPrompt) async -> Bool
}
```

A feature says *why* it needs an account and awaits a yes or no. It does not know that the flow is a chooser sheet that can chain into a login sheet or a create-account sheet, or that sheets are involved at all. `AuthenticationPrompt` lets the ask read as part of what the user was doing — the wishlist button asks "Log in or create an account to build your wishlist", not "Account Required".

**[`UI/AuthUI/Sources/AuthUIHost/AuthPresenter.swift`](UI/AuthUI/Sources/AuthUIHost/AuthPresenter.swift)** implements it as a chain of `SheetPresenting` presentations, holding every caller on a `CheckedContinuation` and resolving them all with the same answer when the flow ends. `AuthPresenter` is built on the generic sheet primitive and knows nothing about how sheets are hosted — only what this flow is.

---

## Authentication as a Domain Outcome

Putting the previous two sections together produces the pattern that runs through the whole app: **the domain decides that authentication is required; the UI decides what to do about it.**

**[`UI/ProductActionsUI/Sources/UI/Buttons/WishlistButtonViewModel.swift`](UI/ProductActionsUI/Sources/UI/Buttons/WishlistButtonViewModel.swift)**
```swift
switch await add(productId: productId) {
case .success:
    snackbarPresenter.show(Snackbar(
        title: "Added to Wishlist",
        message: "Find it any time in your wishlist.",
        icon: "heart.fill",
        action: undo(by: { await remove(productId: productId) }, sayingSoIfItCannot: snackbarPresenter)
    ))
case .failure(.unauthenticated):
    guard await authPresenter.show(AuthenticationPrompt(
        title: "Save to Your Wishlist",
        message: "Log in or create an account to build your wishlist.",
        icon: "heart.fill"
    )) else { return }
    await self.add()          // authenticated now — resume what they asked for
case .failure(.unavailable):
    snackbarPresenter.show(Snackbar(title: "Couldn't Add to Wishlist", ..., action: .retry { ... }))
}
```

`WishlistError` has two cases and no more: the shopper is not signed in, or the change could not be kept. A disk that would not write, a request that never arrived and an unreadable payload all arrive as `.unavailable`, because they are one fact to a shopper — their wishlist did not change — and nothing in the domain would do anything different with the distinction. Telling them apart here would be the transport's vocabulary leaking inward.

The switch is exhaustive, which is the point: there is no `default:` arm quietly swallowing a failure nobody thought about, and adding a third case would stop the build at every screen that has to decide what to say about it.

**Nothing in this path is `@discardableResult`.** An operation that can fail for a reason the shopper needs telling about must not be silently ignorable — so the undo closures, which are the only callers that used to drop the answer, now report it too. A shopper whose sign-in ends between saving something and tapping Undo would otherwise watch the snackbar disappear as though it had worked.

The ViewModel never asks "is the user logged in?" before acting. It attempts the operation, and authentication becomes a *retryable failure* rather than a precondition scattered across every call site. The user's original intent is preserved across the entire detour: tap heart → prompt → create account → item saved, with no second tap.

The undo closures capture the use cases rather than `self` — a wishlist button in a lazily-rendered grid cell may be discarded the moment the user scrolls, and a snackbar action that outlives its view model must still work.

---

## Application Layer

The application layer is the composition root — the single place where all concrete types are instantiated and wired together.

> *"A Composition Root is a (preferably) unique location in an application where modules are composed together."*
> — Mark Seemann & Steven van Deursen, *Dependency Injection: Principles, Practices, and Patterns* (2019)

**Why a composition root?** If each type constructs its own dependencies, no single place in the codebase represents how the application is wired. Wiring bugs are invisible until runtime and require searching the whole codebase to fix. The composition root makes the dependency graph explicit, visible, and located in one place. It is the only part of the app aware of all concrete types simultaneously.

The application layer is intentionally not unit tested — it contains no logic, only wiring.

**Demos are a different catalog, not commented-out code.** The catalog reaches `CompositionRoot` as
a `Catalog` — a set of use case protocols — so a demo supplies a different one and nothing in the
composition root changes. `Demo.shopThatChangesItsMind()` wraps the real use cases in decorators
that move prices and sell things out, which is how the bag's catching-up behaviour can be shown
without waiting for a real shop to change its mind.

The point is that *both arrangements compile at all times*. A demo switched on by uncommenting lines
does not compile in its off state, so nothing checks it still works, and the only thing keeping it
out of a release is that somebody reads a warning. Here it is one flag, type-checked either way:

```swift
// Demo.swift
enum Demo {
    static let isOn = false     // ← the whole switch
}

// CompositionRoot.swift
static let shared = CompositionRoot(
    catalog: Demo.isOn ? Demo.shopThatChangesItsMind() : .live()
)
```

Nothing below the app layer knows a demo is possible. `Component/Bag` sees ordinary catalog answers
and reacts exactly as it would in production — which is the Liskov Substitution Principle earning its
keep, and the reason the demo is trustworthy as a demonstration at all.

### Three Assemblers, One Root

The composition root is assembled in three phases, named for the three layers the architecture already has.

**[`iPhone/Composition/CompositionRoot.swift`](iPhone/Composition/CompositionRoot.swift)**
```swift
@MainActor
final class CompositionRoot {
    static let shared = CompositionRoot(
        catalog: Demo.isOn ? Demo.shopThatChangesItsMind() : .live()
    )

    let data: DataAssembler
    let domain: DomainAssembler
    let presentation: PresentationAssembler

    init(catalog: Catalog) {
        let data = DataAssembler()
        let domain = DomainAssembler(data: data, catalog: catalog)

        self.data = data
        self.domain = domain
        self.presentation = PresentationAssembler(domain: domain)
    }
}
```

Each phase is handed only the phase before it. `DomainAssembler` cannot reach the presentation layer it is about to be used to build, and `DataAssembler` cannot reach either — so the wiring runs one way and the reading order is the construction order.

This is still **one** composition root in Seemann's sense: a single location where modules are composed. Three assemblers constructed here, in one order, are one root with its phases named — not three places where composition happens. Nothing else in the app may build any of them.

**[`iPhone/Composition/DataAssembler.swift`](iPhone/Composition/DataAssembler.swift)** — every concrete store and client, and nothing else:

```swift
@MainActor
struct DataAssembler {
    let sessionStore: SessionStore
    let authClient: AuthClient
    let searchHistoryStore: SearchHistoryStore
    let wishlistStore: WishlistStore
    let bagStore: BagStore

    static let signInLasts: TimeInterval = 60 * 60 * 24 * 7
}
```

How long a sign-in lasts, the choice of `UserDefaults`, the choice of a file on disk — all decided *here*, and readable as one list. Martin calls this out directly in Chapter 30: the database is a detail. Giving the details their own phase is what makes them a list you can read rather than a handful of lines scattered through a longer initialiser.

**[`iPhone/Composition/DomainAssembler.swift`](iPhone/Composition/DomainAssembler.swift)** — the component containers, built over those stores:

```swift
@MainActor
struct DomainAssembler {
    let session: SessionDI
    let catalog: Catalog
    let searchHistory: SearchHistoryDI
    let wishlist: WishlistDI
    let bag: BagDI

    init(data: DataAssembler, catalog: Catalog) { ... }
}
```

`Catalog` is passed in rather than built from `DataAssembler`, because a demo substitutes a whole catalog of decorated use cases. That is a *domain*-level substitution, not a choice of backend, so it does not belong to the data phase — and it arrives from outside for the same reason it always did.

**[`iPhone/Composition/PresentationAssembler.swift`](iPhone/Composition/PresentationAssembler.swift)** — the feature containers and the tab views, from use cases alone:

```swift
@MainActor
struct PresentationAssembler {
    let navigator: Navigator
    let snackbar: SnackbarUIDI
    let sheet: SheetUIDI

    let onboarding: OnboardingUIDI
    let auth: AuthUIDI
    let productActions: ProductActionsUIDI
    let product: ProductUIDI
    let home: HomeUIDI
    let search: SearchUIDI
    let wishlist: WishlistUIDI
    let bag: BagUIDI
    let account: AccountUIDI

    let homeView, searchView, wishlistView, bagView, accountView: AnyView

    init(domain: DomainAssembler) { ... }
}
```

This phase does not decompose further, and the code says why: the sheet host must exist before the auth flow that presents on it, the auth flow before the navigator that gates on it, and the shared wishlist button before the two features that render one. Presentation depends on presentation. Splitting it again would mean inventing an order the graph does not have.

Tab views are instantiated once at startup and held here. If `TabScreen` called `home.mainView()` on each render, SwiftUI would create a new view identity on every tab switch, destroying all `@State`, scroll positions, and in-flight async tasks.

### Component DI Container

**[`Component/Session/Sources/DI/SessionDI.swift`](Component/Session/Sources/DI/SessionDI.swift)**
```swift
public struct SessionDI {
    public let loginUseCase: LoginUseCase
    public let createAccountUseCase: CreateAccountUseCase
    public let logoutUseCase: LogoutUseCase
    public let getSessionUseCase: GetSessionUseCase
    public let observeSessionUseCase: ObserveSessionUseCase

    @MainActor
    public init(sessionStore: SessionStore, authClient: AuthClient) { ... }
}
```

The container takes the data sources it cannot invent and constructs the repository and every use case internally. Callers receive use case protocols; the repository never escapes the package.

### App Entry Point

There is no forced login gate. `MainViewModel` drives a small phase machine — splash, then welcome for a guest or straight to the tabs for a restored session.

**[`iPhone/Main/MainViewModel.swift`](iPhone/Main/MainViewModel.swift)**
```swift
@MainActor
final class MainViewModel: ObservableObject {
    enum Phase: Hashable { case splash, welcome, onboarding, main }

    @Published private(set) var phase: Phase = .splash

    func onAppear() async {
        guard phase == .splash else { return }
        try? await Task.sleep(for: splashDuration)
        guard phase == .splash else { return }
        phase = getSession().isLoggedIn ? .main : .welcome
    }

    func continueAsGuest() { phase = .main }
    func authenticationFinished() { /* settle, then .main */ }
}
```

Both guards are the same rule stated twice: whatever the splash was waiting for, a shopper who authenticated in the meantime has already moved the app on, and the timer must not move it back.

**[`iPhone/Main/Main.swift`](iPhone/Main/Main.swift)** switches on the phase, and attaches the two hosts at the root:

```swift
TabScreen(navigator: ..., snackbarPresenter: ..., homeView: ..., /* ... */)
    .sheetHost(CompositionRoot.shared.presentation.sheet.presenter)
```

`.snackbarHost(_:)` is attached inside `TabScreen` so snackbars sit above the tab bar. The hosts are the only place the app knows sheets and snackbars exist as SwiftUI constructs.

---

## Navigation Architecture

Navigation is decoupled through three collaborating components: feature navigation protocols, a central `Navigator`, and a `Destination` enum.

**Why decouple navigation?** The naive approach gives each ViewModel a reference to a `Navigator`. Every `*UI` package would then import the application target — a feature module depending on the composition root, which completely inverts the dependency direction. Features would know about the application hosting them, rather than the application knowing about features.

Navigation protocols invert this. Each feature declares the navigation capabilities it needs. The application satisfies them. Features remain ignorant of how or where they are hosted.

**[`UI/SearchUI/Sources/Navigation/SearchNavigation.swift`](UI/SearchUI/Sources/Navigation/SearchNavigation.swift)**
```swift
public protocol SearchNavigation: AnyObject {
    func openCatalog(filter: CatalogFilter)
    func openProductDetails(product: Product)
}
```

`HomeNavigation` and `WishlistNavigation` declare only `openProductDetails(product:)`. `BagNavigation` declares `openProductDetails(id:)` and `switchToBagTab()` — a bag row holds an id and not a product, and "View" on the added-to-bag snackbar has to land somewhere. Each protocol lists exactly the moves its own feature makes, so no feature can reach a route it never asked for.

### Destination and the Auth Gate

`Destination` is a `Hashable` enum centralising all route types. It also declares navigation *policy*: which destinations require an account.

**[`iPhone/Navigation/Destination.swift`](iPhone/Navigation/Destination.swift)**
```swift
public enum Destination: Hashable {
    case catalog(CatalogFilter)
    case productDetails(ProductReference)

    public enum ProductReference: Hashable {
        case id(ProductID)
        case product(Product)
    }

    var requiresAuthentication: Bool {
        switch self {
        case .catalog, .productDetails: false
        }
    }

    @ViewBuilder
    func makeView() -> some View {
        switch self {
        case .catalog(let filter):
            CompositionRoot.shared.presentation.search.catalogResultsView(filter: filter)
        case .productDetails(.id(let id)):
            CompositionRoot.shared.presentation.product.detailView(id: id)
        case .productDetails(.product(let product)):
            CompositionRoot.shared.presentation.product.detailView(product: product)
        }
    }
}
```

There is one `catalog` case rather than one per way of slicing the shop, because `CatalogFilter` already says what the slice is — a route per filter would restate that enum in a second place. `ProductReference` exists because a caller that already holds the product can render the screen without a round trip, and a caller holding only an id cannot; both are the same destination.

Every destination is currently public, but the switch is exhaustive: adding an account-only destination forces a decision at compile time rather than leaving a gap. `makeView()` delegates construction to the owning UIDI container, keeping view creation in the DI layer — note that `.productDetails` is served by `ProductUIDI`, not by whichever feature pushed it.

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

    /// Single entry point for all navigation — taps and deep links alike.
    func open(_ destination: Destination, tab: Tabs? = nil) {
        if destination.requiresAuthentication {
            Task { [weak self] in
                guard let self, await self.authPresenter.show(.default) else { return }
                self.push(destination, tab: tab)
            }
        } else {
            push(destination, tab: tab)
        }
    }
}
```

`open` is the only way in, so the gate cannot be bypassed by a new call site — the same principle as putting the wishlist's auth check in the use case rather than at every caller. `Account` has no `NavigationPath` of its own: it is a single screen with no push destinations, so it is excluded from the `push`/`pop` switches rather than carrying dead cases.

### Navigation Flow

1. User taps a button in a `View`
2. `View` calls its navigation protocol (e.g. `SearchNavigation`), and its `ViewModel` for any side effects
3. `Navigator` — which conforms to every feature protocol, in `Destination.swift` where the conformance's dependencies live — receives the call
4. `Navigator.open()` applies the auth gate if the destination requires it
5. `push()` appends the `Destination` to the active tab's `NavigationPath`, switching tabs first if the destination targets another
6. SwiftUI's `NavigationStack` calls `.navigationDestination(for: Destination.self)`
7. `Destination.makeView()` constructs the view via the owning UIDI container

---

## Testing Strategy

> *"The Fragile Tests Problem: ...the system becomes rigid. Developers see that trivial changes to the system can cause massive test failures."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 28

**Every package has exactly one test target, and it is an acceptance suite.** There are no separate domain, use case or repository test targets. A shopper never experiences a repository; they experience their bag being where they left it, at the price they were quoted. That is what is asserted.

Each suite drives its feature through a **testing API** — Martin's own remedy for fragile tests — written in the shopper's language:

**[`Component/Bag/Tests/BagAcceptanceTests/Support/Shopper.swift`](Component/Bag/Tests/BagAcceptanceTests/Support/Shopper.swift)**
```swift
let shopper = Shopper()
shopper.choose(productId: 1, atPrice: 9.99)

shopper.shopSays(shopSells(1, at: 12.99))

#expect(shopper.news.priceMoves == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
#expect(shopper.bag.total == usd(12.99))
```

No test names a repository, a store, a DTO or a `Default*UseCase`. The feature can be rearranged underneath these tests and they go on asserting the same thing — which is the whole point of a testing API, and the reason the layer tests they replaced were worth deleting rather than keeping.

**What is stood in for is only what the app genuinely cannot own.** `Shopper` wires the real `BagDI` over a real `FileBagStore` in a temporary directory: real repository, real DTOs, real JSON on a real disk. `Shop` fakes the catalog at the `HTTPClient` boundary, so the real client, decoding, repository and use cases all run. `Account` uses the same `FakeAuthClient` the app ships. Only the session — which every other component is a *reader* of and never an owner — is stubbed.

That is not a stylistic preference. The first thing this rewrite found was that one unreadable notice in a saved bag threw away the shopper's entire bag: no layer test caught it, because none of them ever went through real JSON.

| Suite | What it asserts |
| --- | --- |
| [`BagAcceptanceTests`](Component/Bag/Tests/BagAcceptanceTests/UsingTheBagTests.swift) | Choosing, repricing, leaving and coming back, and everything the shop can change while a shopper is away |
| [`ProductAcceptanceTests`](Component/Product/Tests/ProductAcceptanceTests/ShoppingTheCatalogTests.swift) | Browsing, paging, searching, categories, and every way the shop can fail to answer |
| [`SessionAcceptanceTests`](Component/Session/Tests/SessionAcceptanceTests/GettingAnAccountTests.swift) | Signing up, signing in, what the form refuses, and staying signed in across launches |
| [`WishlistAcceptanceTests`](Component/Wishlist/Tests/WishlistAcceptanceTests/SavingProductsTests.swift) | Saving, the heart on a card, and the account a list belongs to |
| [`SearchHistoryAcceptanceTests`](Component/SearchHistory/Tests/SearchHistoryAcceptanceTests/SearchingAgainTests.swift) | Recent searches, whose they are, and what counts as a search |
| [`OrderAcceptanceTests`](Component/Order/Tests/OrderAcceptanceTests/BuyingSomethingTests.swift) | Buying, what an order records, a declined payment, and coming back to what you bought |
| [`BagUIAcceptanceTests`](UI/BagUI/Tests/BagUIAcceptanceTests/TheBagScreenTests.swift) | The bag screen: what it asks the shop, when, and what it shows while waiting |
| [`OrderUIAcceptanceTests`](UI/OrderUI/Tests/OrderUIAcceptanceTests/BuyingFromAProductPageTests.swift) | Buy Now and checking out: what each one buys, what it leaves behind, and who it asks to sign in |
| [`WishlistUIAcceptanceTests`](UI/WishlistUI/Tests/WishlistUIAcceptanceTests/KeepingAnEyeOnThingsTests.swift) | Both saved lists: filling them in, paging, and telling a dropped connection from a product that has gone |
| [`MoneyTests`](Library/Money/Tests/MoneyTests/MoneyTests.swift) | The one exception — a `Library/` has no shopper, and owes exact arithmetic to whoever links it |

**Why does this matter?** Tests that require a simulator run slowly and fail for infrastructure reasons unrelated to the logic being tested. Tests that depend on a real network are non-deterministic. Protocol-based design means a whole feature can be assembled and driven in-process, deterministically, in milliseconds. No third-party mocking libraries are needed — a conforming struct is sufficient.

The UI packages other than `BagUI`, `OrderUI`, `ProductActionsUI` and `WishlistUI` are not yet covered — the seams are in place, the tests are not.

---

## Module Dependencies

```
iPhone (App)
├── SessionDI    ──▶  Session ◀── SessionData
├── ProductDI    ──▶  Product ──▶ Money
│                ◀──  ProductData  ──▶  Networking
├── SearchHistoryDI ──▶ SearchHistory ──▶ Product
│                    ◀── SearchHistoryData ──▶ Session
├── WishlistDI   ──▶  Wishlist ──▶ Product, Session
│                ◀──  WishlistData
├── BagDI        ──▶  Bag      ──▶  Product, Money
│                ◀──  BagData  ──▶  Session
├── OrderDI      ──▶  Order    ──▶  Product, Money, Session
│                ◀──  OrderData
├── SheetUIDI    ──▶  SheetUI
├── SnackbarUIDI ──▶  SnackbarUI
├── AuthUIDI     ──▶  AuthUI, Session, SheetUI
├── ProductActionsUIDI ──▶ ProductActionsUI ──▶ Wishlist, Bag, StockAlert, Product,
│                                              SnackbarUI, AuthUI
├── ProductUIDI  ──▶  ProductUI   ──▶  Product
│                ──▶  ProductActionsUIDI
├── HomeUIDI     ──▶  HomeUI      ──▶  Product, Money, SnackbarUI
├── SearchUIDI   ──▶  SearchUI    ──▶  Product, Money, SearchHistory, ProductUI, SnackbarUI
│                ──▶  WishlistUIDI, BagUIDI
├── WishlistUIDI ──▶  WishlistUI  ──▶  Wishlist, StockAlert, Product, Session, ProductUI,
│                                     SnackbarUI, AuthUI
│                ──▶  ProductActionsUIDI
├── BagUIDI      ──▶  BagUI       ──▶  Bag, Product, Money, SnackbarUI
├── OrderUIDI    ──▶  OrderUI     ──▶  Order, Bag, Product, Money, SnackbarUI, AuthUI
│                ──▶  SheetUI
└── AccountUIDI  ──▶  AccountUI   ──▶  Session
                 ──▶  AuthUIDI
```

The rules the graph obeys:

- No domain module depends on a UI or data module.
- No UI module depends on a `*Data` product. UI reaches domain, never storage.
- Feature modules depend on **ports** (`SnackbarUI`, `AuthUI`, `SheetUI`), never on hosts. Only the composition root — and `AuthUIDI`, which is itself a host — links a `*UIDI` host product.
- Cross-feature and cross-component dependencies are allowed where the domain genuinely relates: `Wishlist ──▶ Session` because requiring an account is a real rule, `Bag ──▶ Product` because a bag holds product ids and reads what the shop says about them, `SearchUI ──▶ ProductUI` because a search result is a product card.
- `Bag`'s *domain* reaches `Session` not at all. Only `BagData` does, and only for `Owner` — the bag's rules do not depend on anyone being signed in, and the compiler now says so.
- `Order`'s domain *does* reach `Session`, and the asymmetry is the point: a guest can hold a bag and cannot hold an order, so refusing one is a business rule rather than a storage detail.
- `OrderUI ──▶ Bag`, and never the reverse. `BagUI` is handed a finished checkout button as an `AnyView`, exactly as it is handed a stock alert bell, so the payment stack stays out of the dependency list of every screen that renders a bag row or a heart. `ProductActionsUI` is untouched by checkout for the same reason.
- One `*UIDI` container may take another — `SearchUIDI` takes `BagUIDI` so a search result can carry an add-to-bag button. That is a view-construction dependency between peers, not a reach into a component's domain wiring.
- `Networking` and `Money` have no domain knowledge and sit under `Library/`.

All of it is enforced by the compiler through Swift Package Manager, not by convention.

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

Requires Xcode with the iOS 26 SDK (packages target `.iOS(.v26)`, swift-tools 6.2).

1. Open `CleanArchitecture.xcodeproj`
2. Build and run the `iPhone` scheme
3. Tap **Continue as Guest** to browse Home and Search immediately, against the real [DummyJSON](https://dummyjson.com) catalog
4. Authentication is entirely on-device — create an account with any email and password, then log in with the same credentials. Tapping the heart on a product while signed out will prompt for an account and resume the action once you have one.
5. Sessions persist for seven days and expire automatically; log out from the Account tab

## License

See [LICENSE](LICENSE) for details.
