# Architecture reference

This is the full reference for the architecture. It is written in ASD-STE100 simplified technical English. For an introduction that follows one feature through every layer, read the [README](../README.md) first.

This project shows Clean Architecture in a SwiftUI application. It shows how to separate the parts of an iOS application, how to make each part testable, and how to keep the application easy to change. The architecture follows Robert C. Martin's *Clean Architecture* (2017), Eric Evans' *Domain-Driven Design* (2003), and Martin Fowler's *Patterns of Enterprise Application Architecture* (2002).

---

## Why architecture is important

> *"The goal of software architecture is to minimize the human resources required to build and maintain the required system."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 1

Each architectural decision in this project answers the same question: **how do you keep the cost of a change low while the application becomes larger?**

An iOS codebase with no deliberate structure usually fails in the same way. ViewModels call URLSession directly. Business rules occur in many different UI handlers. Navigation logic becomes part of the screen transitions. You cannot then test the code without a simulator. You cannot change the code until you read all of it. You cannot add to the code without a risk to features that are not related.

The layers and the patterns in this project are not decoration. Each one prevents a specified type of coupling.

---

## Architecture principles

### The dependency rule

> *"Source code dependencies must point only inward, toward higher-level policies."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 22

Dependencies point inward. The domain layer knows nothing about the data layer or the presentation layer. The data layer knows the domain layer, but not the UI. The presentation layer depends on the domain layer, but not on a data source.

```
Presentation ──▶ Domain ◀── Data
     └──────────────────────────▶ (never)
```

**Why this is important.** If the domain layer depended on the data layer, a change of the persistence mechanism would change the business logic. If the business logic were in the ViewModels, you could not test it without a SwiftUI view. The dependency rule keeps each layer replaceable and testable on its own. The direction of the dependencies is the architecture.

### SOLID principles

Robert C. Martin collected the five principles that Michael Feathers subsequently called SOLID in *Agile Software Development, Principles, Patterns, and Practices* (2002). He examines each of them again in *Clean Architecture* (2017), Chapters 7 to 11. Each principle prevents a different cause of code that is difficult to change.

- **Single responsibility** — *"A module should be responsible to one, and only one, actor"* (Ch. 7). An actor is the group of people who ask for a change. The older words — one reason to change — are the historical form that the book replaces, and they hide the point: the reason is always a person, and the defect is two groups of people that share one module. `Component/Bag` answers to the people who decide what a bag holds and which notices the shop leaves on it. `BagUI` answers to the people who decide how a bag row looks. Merchandising and design change on different days, thus they do not share a file. This principle also causes the package layout: it becomes the Common Closure Principle at the level of components, and the axis of change that draws the architectural boundaries above that.

- **Open-closed** — *"A software artifact should be open for extension but closed for modification"* (Ch. 8). New behaviour must come as new code, not as changes to code that already operates. `BagUI` is the example: the application gives checkout to it as a completed `AnyView`, in the same way that it gives a stock alert bell to it. Thus `Order` and `StockAlert` added to the bag screen with no change to `BagUI`. Note what this principle is not: to put one `AuthClient` implementation in the place of another is dependency inversion, not the open-closed principle. To replace a detail keeps the behaviour the same; the open-closed principle adds behaviour.

- **Liskov substitution** — this project has no class inheritance: there is no `override` in the tree. In this condition the principle applies to protocols, and Martin makes that reading explicit — *"the LSP can, and should, be extended to the level of architecture"* (Ch. 9), where the example in the chapter is a REST interface and not a subclass. The principle requires that a conforming type obeys the contract and does not make it smaller. The demo shop tests this in production code and not in a test. `DemoProductRepository` wraps the real `ProductRepository`, changes what the shop says between visits, and `Component/Bag` reacts to it as it reacts to the real one. Thus the decorator must hide a discontinued product from `getProduct(id:)` and not from the lists only. A shop that removed an item from its shelves but still supplied its page would break the bag, and the code says so at that method. The sign of a violation is a caller that must ask which implementation it holds.

- **Interface segregation** — *"avoid depending on things that they don't use"* (Ch. 10). The load falls on the **client**, not on the implementer: a large protocol makes each caller compile against, replace in tests, and understand the methods that it never calls. `SnackbarPresenting` has one method only. Thus a feature says what occurred, and has no control of how long the message stays or how it goes away. Without that limit, a feature that only wants to report an event would also depend on dismissal and duration that it never calls.

- **Dependency inversion** — *"source code dependencies refer only to abstractions, not to concretions"* (Ch. 11). High-level policy must not depend on a low-level detail. The high-level policy here is the use case. `DefaultLoginUseCase` is in `Sources/Domain`, and it depends on the `SessionRepository` **protocol, which is declared in `Sources/Domain` with it** — the domain owns the contract. `DefaultSessionRepository` implements that protocol from `Sources/Data`. Thus the import points from Data to Domain, while the calls go from Domain to Data. That opposition is the inversion, and Swift Package Manager makes it structural: `Session` has no dependency on `SessionData`, thus the compiler refuses the opposite direction. A repository implementation is a detail on the low side of that line, not a high-level module.

### Separation of concerns

> *"Gather into components those classes that change for the same reasons and at the same times. Separate into different components those classes that change at different times and for different reasons."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 13 — the Common Closure Principle

The UI changes for design reasons. Business rules change for product reasons. Data access changes for infrastructure reasons. If these three are in the same module, a person who makes a design change must first find which parts are safe to change and which parts hold business logic that must not break.

Each module in this project has one axis of change. A new screen design changes only the `*UI` modules. A new business rule changes only the domain. A new backend changes only the data layer.

### Repository pattern

> *"Mediates between the domain and data mapping layers using a collection-like interface for accessing domain objects."*
> — Martin Fowler, *Patterns of Enterprise Application Architecture* (2002), Chapter 13

**Why this is important.** Without a repository abstraction, a use case calls the data access code directly. As soon as a use case imports `URLSession` or `UserDefaults`, you cannot test that use case unless the infrastructure is available. The repository protocol states *what* the domain needs from data access. The implementation states *how* the data access satisfies it. The domain does not know the difference.

---

## Project structure

```
├── Component/                  # Domain + Data packages
│   ├── Session/                # Identity, authentication, session lifetime
│   ├── Product/                # Product catalog (DummyJSON-backed)
│   ├── SearchHistory/          # Per-user recent search history
│   ├── Wishlist/               # Per-user wishlist, gated on authentication
│   ├── Bag/                    # Per-shopper bag, and the notices the shop leaves on it
│   ├── Order/                  # What a shopper bought, for how much, and when
│   ├── StockAlert/             # Who asked to be told when something is back
│   ├── Home/                   # What the Home feed draws — Domain only, it stores nothing
│   └── Money/                  # Exact amounts with their currency — Domain only, it stores nothing
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
│   └── Networking/             # Shared HTTP client, no domain dependencies
└── iPhone/                     # Application layer — composition root
    ├── Composition/            # CompositionRoot + its three assemblers, Catalog, and the demo's second root
    ├── Navigation/             # Navigator + Destination
    └── Main/                   # App entry point, phases, tab screen
```

Each of these directories is a different Swift package. This is not only organization, it is enforcement. The Swift compiler makes sure that `HomeUI` cannot import `WishlistUI` unless the package declares that dependency. Architectural boundaries that depend on convention become weak with time. Module boundaries that depend on the compiler do not.

The packages are grouped by role. `Component/` holds domain and data, `UI/` holds presentation, and `Library/` holds shared infrastructure with no domain dependencies. Thus the folder tree reads as the architecture and not as an alphabetical list.

The application has five tabs. **Home** and **Search** show the real [DummyJSON](https://dummyjson.com) product catalog. **Wishlist** needs an account. **Bag** also operates for a guest, and tells the shopper what the shop changed while they were away. **Account** shows the profile of the signed-in shopper, or a guest state. A guest can use the application throughout. The application asks for authentication at the moment it is necessary, and not as a gate at start-up.

---

## Architecture layers

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

## Domain layer

The domain layer holds the business logic. It has **no dependencies** on external frameworks, on the UI, or on data sources. You can compile it, test it and understand it on its own.

**Why the domain layer is isolated.** The domain is the most valuable and the most stable part of the application. Business rules change for business reasons. They do not change because SwiftUI has a new API, or because the backend changed from REST to GraphQL. A domain with no framework dependencies stays correct through a change of technology. Martin calls this the *Stable Dependencies Principle*: depend in the direction of stability.

### Entities

> *"An object defined primarily by its identity is called an ENTITY."*
> — Eric Evans, *Domain-Driven Design* (2003), Chapter 5

Entities are the primary business objects. They are immutable and independent of the frameworks. They hold no persistence data and no UI data. A `User` is a `User` whatever fetched it, whatever shows it, and wherever it is kept.

**[`Component/Session/Sources/Domain/Model/User.swift`](../Component/Session/Sources/Domain/Model/User.swift)**
```swift
public struct User: Equatable, Sendable, Identifiable {
    public let id: UserID
    public let email: Email
    public let name: PersonName
}
```

Each field is a type and not a `String` or an `Int`. You cannot give a `UserID` where a `ProductID` is necessary. An `Email` has satisfied the rule about the format of an address; a `String` has not. `PersonName` states that a last name is optional, because many people have one name only. Without the type, that intent stays in a test.

The authentication state is a sum type, not an optional user with a boolean flag. The two-field form permits states that cannot exist, for example "logged in, no user". The enumeration does not permit them.

**[`Component/Session/Sources/Domain/Model/Session.swift`](../Component/Session/Sources/Domain/Model/Session.swift)**
```swift
public enum Session: Equatable, Sendable {
    case guest
    case authenticated(User)

    public var user: User? { ... }
    public var isLoggedIn: Bool { ... }
}
```

`CategoryID` and `ProductID` are deliberate for the same reason. A raw `String` category is interchangeable with a title, a search term or a product name. A raw `Int` product id is interchangeable with a user id or a quantity. The compiler cannot tell you when a caller exchanges them. A wrapper type removes that group of faults. An identity is also the one part of another aggregate that a context can safely hold, which is why it earns a type.

**[`Component/Product/Sources/Domain/Model/Product.swift`](../Component/Product/Sources/Domain/Model/Product.swift)**
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

`price` is a `Money` and not a `Double`. A price such as 9.99 has no exact binary value. Thus a total that adds such prices moves away from the correct amount, and two amounts that must be equal compare as different. That is more than an untidy result here, because the application compares two amounts to decide if it must tell a shopper that a price changed. `Money` counts whole minor units and holds its currency with the amount.

`availability` is one idea, not a stock count with a will-it-return flag. The flag has a meaning only when the count is zero. Thus each caller must know that rule to read either field, and callers then build the same three states again in different ways.

```swift
public enum Availability: Equatable, Hashable, Sendable {
    case inStock(remaining: Int)
    case outOfStock      // the shop expects to have it again
    case discontinued    // the shop is not selling it any more
}
```

### Use cases

> *"The software in this layer contains application-specific business rules... These use cases orchestrate the flow of data to and from the entities."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 22

Each use case is a protocol that names one business operation, with a `Default*` struct that implements it. Both are in the domain. Callers depend on the protocol. The DI container constructs the struct.

The application calls a use case through `callAsFunction`. Thus a call reads as the operation itself — `await login(email:password:)`, `await addProductToWishlist(productId:)` — and not as `loginUseCase.execute(...)`.

**Why use cases are necessary.** Without them, business logic moves into the ViewModels, into the repositories and finally into the views. The question "where does login occur?" then has no clear answer. A use case gives a business operation one location. You can test it with no UI, no network, and no knowledge of the remainder of the system.

**[`Component/Session/Sources/Domain/UseCases/LoginUseCase.swift`](../Component/Session/Sources/Domain/UseCases/LoginUseCase.swift)**
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

Note the location of the validation. "That is not an email address" is a business rule and not a UI concern. Thus the use case applies it one time, and each caller gets it. The use case decides only the sequence of the questions. `Email` owns the rule about a valid address, and `Password` owns the rule about a valid password. The login sheet shows the error; it does not decide what an error is.

You can find the full vocabulary of the application when you read the domain alone.

| Component | Use cases |
| --- | --- |
| `Session` | `LoginUseCase`, `CreateAccountUseCase`, `LogoutUseCase`, `GetSessionUseCase`, `ObserveSessionUseCase` |
| `Product` | `BrowseCatalogUseCase`, `ViewProductUseCase`, `LookUpProductsUseCase`, `BrowseCategoriesUseCase` |
| `SearchHistory` | `GetSearchHistoryUseCase`, `RecordSearchUseCase`, `ClearSearchHistoryUseCase` |
| `Wishlist` | `ObserveWishlistUseCase`, `ObserveProductIsWishlistedUseCase`, `AddProductToWishlistUseCase`, `RemoveProductFromWishlistUseCase` |
| `Bag` | `ObserveBagUseCase`, `ObserveNoticesUseCase`, `ObserveBagItemQuantityUseCase`, `AddItemToBagUseCase`, `SetBagItemQuantityUseCase`, `BringBagUpToDateUseCase`, `AcknowledgeNoticesUseCase` |
| `Order` | `PlaceOrderUseCase`, `ObserveOrdersUseCase` |

Each name states something that a shopper wants to do. That is the test that a use case name must satisfy. `LookUpProductsUseCase` describes how the application fills in the items on a list that the shopper already has. `getProductsByIds` would describe only the query that it uses. If you name the use case layer after the methods of the repository, the layer that must list the intentions of the application lists its data access instead.

### Use cases that call other use cases

The domain of `Wishlist` depends on the domain of `Session`, and that dependency is the point. A shopper must have an account to save a wishlist item. That is a business rule, thus the domain applies it. A view that remembers to make the check first does not.

**[`Component/Wishlist/Sources/Domain/UseCases/AddProductToWishlistUseCase.swift`](../Component/Wishlist/Sources/Domain/UseCases/AddProductToWishlistUseCase.swift)**
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

`.unauthenticated` is a domain outcome. The UI must respond to it — see [Authentication as a domain outcome](#authentication-as-a-domain-outcome) — and must not try to predict it. A new caller of this use case cannot forget the rule, because the rule is not the caller's to remember.

**A component that is only composition.** `Home` is the limit of this pattern. Its one use case draws the feed with two use cases from `Product`: list the categories of the shop, and list the products of a category. It then decides which categories get a carousel, and how many. `Home` has no repository, no store and no `Sources/Data` target, because the application derives a feed at each draw and does not keep it. A component is an axis of change and not a folder layout. `Home` owns a rule, and the rule must be in a location where no screen can change it quietly.

**[`Component/Home/Sources/Domain/UseCases/DrawHomeFeedUseCase.swift`](../Component/Home/Sources/Domain/UseCases/DrawHomeFeedUseCase.swift)**
```swift
public struct DefaultDrawHomeFeedUseCase: DrawHomeFeedUseCase {
    private let browseCatalog: BrowseCatalogUseCase
    private let browseCategories: BrowseCategoriesUseCase

    public func callAsFunction() async -> Result<HomeFeed, HomeError> {
        guard case .success(let categories) = await browseCategories(), !categories.isEmpty else {
            return .failure(.unavailable)
        }
        var carousels: [HomeCarousel] = []
        for category in categories.shuffled() {
            guard carousels.count < maxCarousels else { break }
            guard let products = await qualifyingProducts(for: category) else { continue }
            carousels.append(HomeCarousel(category: category, products: products))
        }
        guard let feed = HomeFeed(carousels: carousels) else { return .failure(.unavailable) }
        return .success(feed)
    }
}
```

The initialiser of `HomeFeed` can fail, and it refuses an empty list. Thus a screen cannot read "the shop had nothing to draw" as a feed that it must show. `HomeScreenViewModel` then holds three states and four methods that delegate.

### Repository contracts

The domain layer declares the repository protocols. The data layer does not. This is the dependency inversion principle in its direct form: the domain states the interface that it needs, and the data layer satisfies that interface. The domain is not a client of the data layer. The data layer is a plugin to the domain.

**[`Component/Session/Sources/Domain/Repository/SessionRepository.swift`](../Component/Session/Sources/Domain/Repository/SessionRepository.swift)**
```swift
public protocol SessionRepository: Sendable {
    @MainActor var sessionPublisher: AnyPublisher<Session, Never> { get }
    @MainActor var currentSession: Session { get }

    func login(email: Email, password: Password) async -> Result<Void, LoginError>
    func createAccount(name: PersonName, email: Email, password: Password) async -> Result<Void, CreateAccountError>
    func logout() async
}
```

**Why `SearchHistory` is a different component from `Product`.** The search history and the product catalog change for different reasons, and they have different storage. Recent searches are local to one user and disposable. The catalog is remote and shared. If the two were one component, a concern that `UserDefaults` holds and a concern that the network holds would be behind the same contract. `SearchHistory` depends on `Session`, because the history belongs to one user. It depends on `Product` for `SearchTerm` only. What counts as a search, and when two searches are the same search, is one rule in one location.

---

## Data layer

The data layer implements the domain contracts and does all the external work: the network, persistence, hashing and token lifetime. It depends on the domain layer. The domain layer knows nothing about it.

**Why the data layer is separate.** Infrastructure details change frequently. APIs change. An authentication mechanism is replaced. A caching strategy is improved. The repository contract keeps these details in one place, thus no such change moves inward to the domain or outward to the UI.

### Repository implementation

`DefaultSessionRepository` controls the data sources, changes the infrastructure errors into domain error types, and satisfies the `SessionRepository` contract. The error mapping at the boundary is deliberate. A domain error type must not hold a code that belongs to the infrastructure, because the domain must not know that authentication uses a client.

**[`Component/Session/Sources/Data/DefaultSessionRepository.swift`](../Component/Session/Sources/Data/DefaultSessionRepository.swift)**
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

On the create-account path, `AuthClientError.emailAlreadyInUse` becomes `CreateAccountError.emailAlreadyInUse`. On the login path it becomes `.unavailable`. The mapping is different for each operation because the failures that have a meaning are different for each operation. One shared error enumeration would make each caller handle cases that cannot occur.

### Data sources

The data sources are protocols. To test `DefaultSessionRepository`, give it a fake `AuthClient` and a fake `SessionStore`. The test needs no network, no simulator and no `UserDefaults`.

**[`Component/Session/Sources/Data/Auth/AuthClient.swift`](../Component/Session/Sources/Data/Auth/AuthClient.swift)**
```swift
public protocol AuthClient: Sendable {
    func login(email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError>
    func createAccount(name: PersonName, email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
```

`FakeAuthClient` is the implementation that the application contains now. It registers accounts on the device in a `UserStore`. It keeps passwords as SHA-256 hashes. It makes tokens locally, with a user id that it derives from the email address, thus the same account always gives the same wishlist. To use a real backend, write one new `AuthClient` conformance and change one line in the composition root. No domain code, presentation code or navigation code moves. This is the value of the Liskov substitution principle.

### Session lifetime is a data concern

**[`Component/Session/Sources/Data/Session/SessionStore.swift`](../Component/Session/Sources/Data/Session/SessionStore.swift)**
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

At start-up, `DefaultSessionStore` restores a session that it kept, if the token of that session is still valid. If the token is not valid, it removes the session. It also starts a task that clears the session at the moment that the token becomes invalid. Each observer of `sessionPublisher` then reacts to the expiry: the wishlist repository, the account screen and the root phase of the application. None of them holds expiry logic. The rule is in one location, and all the other behaviour is a result of it.

### Storage for each shopper

`Bag`, `Settings` and `SearchHistory` each keep data for one shopper, and they key it on the `Session` itself. A guest has a real bag and a real search history, because a person can shop before they sign in. Thus the guest case of `Session` is a real owner of data and not the absence of one.

There was a smaller `Owner` type between the session and the storage, which held a guest case or an id and nothing else. It is removed. Two types with the same shape, one of them holding only an id, cost more to learn than they saved while nothing else drew on them.

**[`Component/Bag/Sources/Data/DefaultBagRepository.swift`](../Component/Bag/Sources/Data/DefaultBagRepository.swift)**
```swift
private func switchSession(to session: Session) {
    guard session.user?.id != self.session.user?.id else { return }
    self.session = session
    let kept = store.getBag(for: session)
    bagSubject.value = kept.bag
    noticesSubject.value = kept.notices
}
```

Note the comparison. It is on the id and not on the whole session, because a session also changes when a profile does, and a changed name is not a changed owner. That is what the smaller type used to make impossible to get wrong; with a `Session` the caller must get it right, and `data-reads-who-is-signed-in-and-nothing-else` keeps the rest of the module out of the data layer.

`Wishlist`, `StockAlert` and `Order` key on a `UserID?` instead. A guest cannot save an item, cannot wait for one and cannot place an order, thus there is no guest case to handle. The shape differs because the rule differs.

Note what the application gives to the repository: an owner, and a stream of owners. It does not give a `Session` or a session use case. The repository must know whose bag is active. It does not have to understand identity. `BagDI` does that translation one time at the wiring boundary. The name that a bag is filed under is the business of the storage layer, and the only code that changes an owner back into a string is the code that selects a filename.

`DefaultWishlistRepository` and `DefaultSearchHistoryRepository` have the same shape for the same reason. The application tells all three who it keeps data for. None of the three can reach a session to ask.

### DTOs

The DTOs are in the data layer and never move inward. `ProductDTO`, `ProductCategoryDTO`, `WishlistItemDTO`, `BagDTO`, `BagItemDTO`, `NoticeDTO`, `OrderDTO`, `OrderLineDTO`, `SessionSnapshotDTO` and `StoredUser` are the `Codable` types. Each one maps to a domain model at the repository boundary. A domain model has no `Codable` conformance, because serialisation is a storage detail. A `Codable` entity couples the shape of the domain to a wire format, and it does that quietly.

### Shared networking

`Library/Networking` is a Swift package with no dependencies. It supplies `HTTPClient`, a small protocol with a default implementation, `URLSessionHTTPClient`. That implementation maps transport failures, status failures and decoding failures onto `HTTPClientError`.

**[`Library/Networking/Sources/Networking/HTTPClient.swift`](../Library/Networking/Sources/Networking/HTTPClient.swift)**
```swift
public protocol HTTPClient: Sendable {
    func get<T: Decodable>(_ url: URL) async throws -> T
    func post<Body: Encodable, T: Decodable>(_ url: URL, body: Body) async throws -> T
}
```

It is in `Library/` and not in `Component/` because it holds no domain knowledge. It would be the same in a completely different application.

---

## Presentation layer

The presentation layer uses MVVM. The views are passive and show state. The ViewModels hold `@Published` state and send business operations to the use cases. Neither the views nor the ViewModels know about repositories or data sources.

**Why MVVM.** A SwiftUI view is a value type, and the framework makes it again frequently. Business logic in a view is destroyed with the view. A ViewModel is a reference type and stays through that cycle. More importantly, you cannot unit-test a view, but you can unit-test a ViewModel. If the logic is in the ViewModel and the view is only declarative, you can examine the presentation behaviour without a rendered pixel.

### Structure of a feature module

Most feature packages have this layout:

```
FeatureUI/
├── Sources/
│   ├── UI/              # Views and ViewModels
│   ├── Navigation/      # Feature navigation protocol
│   └── DI/              # Feature DI container
└── Tests/
```

### ViewModels

A ViewModel is a `@MainActor ObservableObject` class. It receives **use case protocols** through its initialiser. It never receives a repository, a store or a data source. A test of `AuthViewModel` needs no network stack and no session. It needs an object that satisfies `LoginUseCase`.

**[`UI/AuthUI/Sources/AuthUIHost/AuthViewModel.swift`](../UI/AuthUI/Sources/AuthUIHost/AuthViewModel.swift)**
```swift
@MainActor
final class AuthViewModel: ObservableObject {
    private let loginUseCase: LoginUseCase
    private let createAccountUseCase: CreateAccountUseCase
    private let onAuthenticated: () -> Void

    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: String?

    func submit() async {
        guard canSubmit else { return }
        error = nil
        isLoading = true
        defer { isLoading = false }

        switch mode {
        case .logIn:
            switch await loginUseCase(email: Email(email), password: Password(password)) {
            case .success:
                confirmationMessage = greeting("Welcome back")
                onAuthenticated()
            case .failure(let failure):
                error = AuthenticationErrorMessages.message(for: failure)
            }
        case .createAccount:
            { ... }   // the same shape, through createAccountUseCase
        }
    }
}
```

The text that a person types becomes an `Email` and a `Password` here, at the edge. This is the only location where a loose string is permitted. The two types are deliberately tolerant, thus a partly typed address is still valid while the person types it. `AuthenticationErrorMessages` is in `AuthUI`: the domain says *what* failed, and the presentation decides *how to say it*. A change to the text never changes `Session`.

`AuthenticationErrorMessages` is its own type and not an extension on `LoginError`. This is deliberate. Another module declares `LoginError`, and behaviour that this module adds to it would not be visible to a person who reads that module. An extension across a module boundary hides part of a type's surface from the file that declares the type. The rule in this codebase is that an extension can only be beside the type that it extends. Each extension outside a test obeys that rule.

### Views

A view binds to the `@Published` properties and sends each action to the ViewModel. A view contains no business branch, no network call and no navigation decision. It answers one question: for this state, what must be on the screen?

### Shared UI components

`ProductUI` is a UI package with no tab of its own. It owns the product card, the two arrangements of cards — a paginating grid down the screen and a scrolling row across it — and the product details screen. `HomeUI`, `SearchUI` and `WishlistUI` all need these, and none of them must own them. The views of `ProductUI` take an `accessory` closure. Thus a host feature can add a wishlist button, and `ProductUI` does not learn what a wishlist is.

The row shows this clearly. A carousel on Home and a carousel on the wishlist tab are the same row of the same cards. Only the heading above them is different, and each feature keeps its own heading. If the row stayed in `HomeUI`, then `WishlistUI` would import `HomeUI`. But `HomeUI` already imports `WishlistUI` to draw the hearts, thus that is a cycle, and SwiftPM refuses to build it. The arrangement of a card belongs with the card.

`ProductActionsUI` is the same idea one level lower, and its name states what it is and not who uses it. It holds the three things that a shopper can do to a product — save it, buy it, and ask to be told when it is available again — and the decision about which of them to offer for a given availability.

These are not feature buttons that two features share. A heart belongs to the product and not to the wishlist feature. The set of actions changes for one reason only: when what a shopper can do with a product changes. That is one axis of change, which is the test for what belongs together.

There is also a mechanical reason. `BagUI` draws the heart, in the list of removed items. `WishlistUI` draws the bag button, on each row. If each button were in the package of its own feature, that is a cycle, and SwiftPM refuses to build it.

A package with the name `SharedUI` would cause the opposite question. A name that states a *relationship* to other packages gives no criterion for what goes in it, thus everything goes in it. A name that states the concept writes the rule for you: if it is not something that a shopper can do to a product, it does not go here.

**Cross-feature UI dependencies are permitted and intentional.** `SearchUI` imports `ProductUI`. `WishlistUI` imports `ProductUI`, `ProductActionsUI` and `AuthUI`. What is not permitted is a UI package that imports the *data* layer of another component.

### DI containers for each feature

Each feature module supplies a DI container that constructs its view hierarchy. The container takes its dependencies through its initialiser: navigation protocols, presentation ports and single use cases.

**Why each feature has its own DI container.** One large injector that constructs each view in the application mixes the wiring of features that are not related. With a container for each feature, each feature constructs its own objects. `CompositionRoot` assembles the containers, and the containers assemble the views.

**[`UI/HomeUI/Sources/DI/HomeUIDI.swift`](../UI/HomeUI/Sources/DI/HomeUIDI.swift)**
```swift
public struct HomeUIDI {
    private let navigation: HomeNavigation
    private let drawHomeFeed: DrawHomeFeedUseCase
    private let wishlistUIDI: WishlistUIDI
    private let productActionsUIDI: ProductActionsUIDI

    @MainActor
    public func mainView() -> some View {
        HomeScreenView(
            viewModel: HomeScreenViewModel(drawHomeFeed: drawHomeFeed, navigation: navigation),
            wishlistButton: { id in AnyView(wishlistUIDI.button(productId: id)) },
            bagButton: { product in AnyView(productActionsUIDI.cardActionButton(product: product)) }
        )
    }
}
```

**Why single use cases and not the full `ProductDI` container.** This is the interface segregation principle applied to dependency injection. `HomeUIDI` needs one capability — draw the feed — thus it gets one. `HomeDI`, one layer further in, needs two capabilities from `Product`: list the categories of the shop, and list the products in one category. The full `ProductDI` at either point would also supply `viewProductUseCase` and `lookUpProductsUseCase`, which neither of them calls. Fowler warns against this shape with the name Service Locator: a container that *can* resolve anything, in the place of the collaborator that the caller actually needs, makes the boundary less clear. Only the composition root holds a full component container.

There is one exception: a UI container can take another UI container. `HomeUIDI` takes `WishlistUIDI` and `ProductActionsUIDI`, thus a card in a carousel can carry a heart and a bag button. `SearchUIDI` takes the same pair for the same reason. That is a view-construction dependency between equals and not a reach into the domain wiring of a component. Note where it stops: the two containers reach `HomeUIDI` and not `HomeUI`. The screen itself gets two closures, `(ProductID) -> AnyView` and `(Product) -> AnyView`, and never learns that a wishlist exists.

---

## Ports and hosts: UI that crosses features

Three UI concerns — sheets, snackbars and authentication — are necessary for features that must not know how the application implements them. Each concern is a package in two parts: a **port** and a **host**.

```
SnackbarUI/
├── Sources/
│   ├── SnackbarUI/       # product `SnackbarUI`   — the port: protocol + value types
│   ├── SnackbarUIHost/   # the SwiftUI implementation
│   └── SnackbarUIDI/     # the container that constructs it
└── product `SnackbarUIDI` = SnackbarUIHost + SnackbarUIDI
```

**A feature links the port. Only the composition root links the host.** `HomeUI` depends on `SnackbarUI` and can call `show(_:)`. It cannot see `SnackbarPresenter`, `SnackbarView` or the `.snackbarHost(_:)` modifier, because those are in a product that `HomeUI` does not link. SwiftPM applies this boundary. Discipline does not.

### SheetUI — the primitive

**[`UI/SheetUI/Sources/SheetUI/SheetPresenting.swift`](../UI/SheetUI/Sources/SheetUI/SheetPresenting.swift)**
```swift
@MainActor
public protocol SheetPresenting: AnyObject {
    func present<Content: View>(onDismiss: (() -> Void)?, @ViewBuilder content: () -> Content)
    func dismiss()
}
```

`SheetPresenter` makes sure that only one sheet is on the screen at a time. If a caller presents a sheet while a sheet is open, `SheetPresenter` puts the new sheet in a queue and lets the open sheet complete its dismissal. Thus SwiftUI receives a clean pair of one dismissal and one presentation. `onDismiss` occurs *only* when the shopper ends the sheet. It does not occur when a chained sheet replaces that sheet, and it does not occur on a `dismiss()` from code. That difference is what permits a flow that carries an outcome.

### SnackbarUI — one method, deliberately

**[`UI/SnackbarUI/Sources/SnackbarUI/Snackbar.swift`](../UI/SnackbarUI/Sources/SnackbarUI/Snackbar.swift)**
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

`displayDuration` belongs to the snackbar and not to the object that shows it. How long a message stays is a property of the message. A host that decided the duration would have to know the meaning of each message. The caller supplies the actions: `.undo` carries the opposite operation, `.retry` calls the failed operation again, and `.view` goes to the item. Thus `SnackbarUI` never learns what a wishlist or a bag is.

### AuthUI — a flow behind one call

**[`UI/AuthUI/Sources/AuthUI/AuthPresenting.swift`](../UI/AuthUI/Sources/AuthUI/AuthPresenting.swift)**
```swift
@MainActor
public protocol AuthPresenting: AnyObject {
    /// - Returns: `true` if the user is authenticated — they already were, or they just
    ///   completed the flow. `false` if they dismissed it first.
    @discardableResult
    func show(_ prompt: AuthenticationPrompt) async -> Bool
}
```

A feature says *why* it needs an account, then waits for yes or no. It does not know that the flow is a chooser sheet that can continue into a login sheet or a create-account sheet. It does not know that the flow uses sheets at all. `AuthenticationPrompt` lets the question read as part of what the shopper was doing: the wishlist button asks "Log in or create an account to build your wishlist", not "Account Required".

**[`UI/AuthUI/Sources/AuthUIHost/AuthPresenter.swift`](../UI/AuthUI/Sources/AuthUIHost/AuthPresenter.swift)** implements the protocol as a chain of `SheetPresenting` presentations. It holds each caller on a `CheckedContinuation`, and gives all of them the same answer when the flow ends. `AuthPresenter` is built on the generic sheet primitive. It knows only what this flow is, and nothing about how the application hosts a sheet.

---

## Authentication as a domain outcome

The two sections above give the pattern that occurs through the full application: **the domain decides that authentication is necessary, and the UI decides what to do about it.**

**[`UI/ProductActionsUI/Sources/UI/Buttons/Wishlist/WishlistButtonViewModel.swift`](../UI/ProductActionsUI/Sources/UI/Buttons/Wishlist/WishlistButtonViewModel.swift)**
```swift
switch await add(productId: productId) {
case .success:
    snackbarPresenter.show(Snackbar(
        title: "Saved",
        message: "It's in your faves.",
        icon: "heart.fill",
        action: undo(
            by: { await remove(productId: productId) },
            sayingSoIfItCannot: snackbarPresenter
        )
    ))
case .failure(.unauthenticated):
    guard await authPresenter.show(AuthenticationPrompt(
        title: "Keep Your Faves",
        message: "Sign in and everything you save sticks around.",
        icon: "heart.fill"
    )) else {
        return
    }
    await self.add()          // authenticated now — resume what they asked for
case .failure(.unavailable):
    snackbarPresenter.show(Snackbar(
        title: "Didn't Save",
        message: "That didn't stick. Try again?",
        icon: "heart.slash",
        action: .retry { Task { await self.add() } }
    ))
}
```

`WishlistError` has two cases and no more: the shopper is not signed in, or the application could not keep the change. A disk that refused to write, a request that did not arrive and a payload that the application cannot read all become `.unavailable`. To a shopper these are one fact — the wishlist did not change — and no part of the domain would act differently on the difference. To separate them here would move the vocabulary of the transport inward.

The switch is exhaustive, which is the purpose. There is no `default:` arm to hide a failure that nobody examined. If a third case is added, the build stops at each screen that must decide what to say about it.

**No part of this path is `@discardableResult`.** An operation that can fail for a reason that the shopper must know about must not be easy to ignore. The undo closures were the only callers that discarded the answer, and they now report it. Without that, a shopper whose sign-in ends between the save and the tap on Undo would see the snackbar go away as if the operation had succeeded.

The ViewModel never asks "is the shopper logged in?" before it acts. It tries the operation, and authentication becomes a *failure that the shopper can retry* and not a precondition in each call site. The application keeps the original intention of the shopper through the full detour: tap the heart, answer the prompt, create the account, and the item is saved, with no second tap.

The undo closures capture the use cases and not `self`. The application can discard a wishlist button in a grid cell as soon as the shopper scrolls, and a snackbar action that stays after its view model must still operate.

---

## Application layer

The application layer is the composition root. It is the one location where the application constructs each concrete type and connects them.

> *"A Composition Root is a (preferably) unique location in an application where modules are composed together."*
> — Mark Seemann & Steven van Deursen, *Dependency Injection: Principles, Practices, and Patterns* (2019)

**Why a composition root is necessary.** If each type constructs its own dependencies, no location in the codebase shows how the application is connected. A wiring fault is then invisible until the application runs, and a person must search the full codebase to correct it. The composition root makes the dependency graph explicit, visible and local. It is the only part of the application that knows all the concrete types at the same time.

There are no unit tests for the application layer, deliberately: it holds no logic, only wiring.

**A demo is a different catalog and not code in comments.** The catalog reaches `CompositionRoot` as a `Catalog`, which is a set of use case protocols. Thus a demo supplies a different catalog, and nothing in the composition root changes. `Demo.shopThatChangesItsMind()` puts the real use cases in decorators that move prices and sell items out. This is how the application can show the catch-up behaviour of the bag without a real shop that changes its mind.

The important property is that *both arrangements compile at all times*. A demo that you enable when you remove comment marks does not compile in its off state, thus nothing shows that it still operates, and only a person who reads a warning keeps it out of a release. Here the demo is one flag, and the compiler checks both states:

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

Nothing below the application layer knows that a demo is possible. `Component/Bag` receives usual catalog answers and reacts as it reacts in production. This is the value of the Liskov substitution principle, and it is the reason that the demo is a reliable demonstration.

### Three assemblers, one root

The application builds the composition root in three phases. The phases have the names of the three layers that the architecture already has.

**[`iPhone/Composition/CompositionRoot.swift`](../iPhone/Composition/CompositionRoot.swift)**
```swift
@MainActor
final class CompositionRoot {
    static let shared = CompositionRoot(
        catalog: Demo.isOn ? Demo.shopThatChangesItsMind() : .live()
    )

    let data: DataAssembler
    let domain: DomainAssembler
    let presentation: PresentationAssembler

    init(catalog: Catalog, data: DataAssembler = DataAssembler()) {
        let domain = DomainAssembler(data: data, catalog: catalog)

        self.data = data
        self.domain = domain
        self.presentation = PresentationAssembler(domain: domain)
    }
}
```

Each phase receives only the phase before it. `DomainAssembler` cannot reach the presentation layer that it helps to build, and `DataAssembler` can reach neither of the other two. Thus the wiring goes in one direction, and the order that you read is the order of construction.

This is still **one** composition root in Seemann's sense: one location where the application composes the modules. Three assemblers constructed here, in one sequence, are one root with named phases. They are not three locations where composition occurs. No other part of the application can build any of them.

**[`iPhone/Composition/DataAssembler.swift`](../iPhone/Composition/DataAssembler.swift)** — each concrete store and client, and nothing more:

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

How long a sign-in stays valid, the selection of `UserDefaults`, the selection of a file on disk — the application decides all of these *here*, and you can read them as one list. Martin states this directly in Chapter 30: the database is a detail. A separate phase for the details is what makes them a list that you can read, in the place of some lines in a longer initialiser.

**[`iPhone/Composition/DomainAssembler.swift`](../iPhone/Composition/DomainAssembler.swift)** — the component containers, built over those stores:

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

The application gives `Catalog` to this phase and does not build it from `DataAssembler`, because a demo replaces a full catalog of decorated use cases. That is a substitution at the *domain* level and not a selection of a backend, thus it does not belong to the data phase. It comes from outside for the same reason that it always did.

**[`iPhone/Composition/PresentationAssembler.swift`](../iPhone/Composition/PresentationAssembler.swift)** — the feature containers and the tab views, from use cases only:

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

This phase does not divide further, and the code shows why. The sheet host must exist before the auth flow that presents on it. The auth flow must exist before the navigator that gates on it. The shared wishlist button must exist before the two features that draw one. Presentation depends on presentation. To divide the phase again, you would have to invent an order that the graph does not have.

The application constructs the tab views one time at start-up and holds them here. If `TabScreen` called `home.mainView()` at each draw, SwiftUI would make a new view identity at each change of tab. That would destroy all `@State`, all scroll positions and all async tasks in progress.

### Component DI container

**[`Component/Session/Sources/DI/SessionDI.swift`](../Component/Session/Sources/DI/SessionDI.swift)**
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

The container takes the data sources that it cannot make itself. It then constructs the repository and each use case internally. A caller receives use case protocols, and the repository never leaves the package.

### Application entry point

There is no login gate at start-up. `MainViewModel` operates a small phase machine: a splash screen, then a welcome screen for a guest, or the tabs directly for a session that the application restored.

**[`iPhone/Main/MainViewModel.swift`](../iPhone/Main/MainViewModel.swift)**
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

The two guards state the same rule two times. Whatever the splash screen waited for, a shopper who authenticated in that time has already moved the application forward, and the timer must not move it back.

**[`iPhone/Main/Main.swift`](../iPhone/Main/Main.swift)** switches on the phase, and attaches the two hosts at the root:

```swift
TabScreen(navigator: ..., snackbarPresenter: ..., homeView: ..., /* ... */)
    .sheetHost(CompositionRoot.shared.presentation.sheet.presenter)
```

`.snackbarHost(_:)` is attached in `TabScreen`, thus a snackbar shows above the tab bar. The hosts are the only location where the application knows that sheets and snackbars are SwiftUI constructs.

---

## Navigation architecture

Navigation uses three parts together: a navigation protocol for each feature, a central `Navigator`, and a `Destination` enumeration.

**Why navigation is decoupled.** The simple approach gives each ViewModel a reference to a `Navigator`. Each `*UI` package would then import the application target. A feature module would depend on the composition root, which reverses the correct direction of the dependencies. The features would know about the application that hosts them, in the place of the application knowing about the features.

The navigation protocols invert this. Each feature declares the navigation that it needs. The application supplies it. A feature does not know how or where the application hosts it.

**[`UI/SearchUI/Sources/Navigation/SearchNavigation.swift`](../UI/SearchUI/Sources/Navigation/SearchNavigation.swift)**
```swift
public protocol SearchNavigation: AnyObject {
    func openCatalog(filter: CatalogFilter)
    func openProductDetails(product: Product)
}
```

`HomeNavigation` and `WishlistNavigation` declare `openProductDetails(product:)` only. `BagNavigation` declares `openProductDetails(id:)` and `switchToBagTab()`, because a bag row holds an id and not a product, and because "View" on the added-to-bag snackbar must go somewhere. Each protocol lists only the moves that its own feature makes. Thus a feature cannot reach a route that it did not ask for.

### Destination and the authentication gate

`Destination` is a `Hashable` enumeration that holds all the route types. It also declares navigation *policy*: which destinations need an account.

**[`iPhone/Navigation/Destination.swift`](../iPhone/Navigation/Destination.swift)**
```swift
public enum Destination: Hashable {
    case catalog(CatalogFilter)
    case productDetails(ProductReference)
    case orderHistory
    case allFaves
    case allWaitlist
    case allBackInStock
    case settings

    public enum ProductReference: Hashable {
        case id(ProductID)
        case product(Product)
    }

    var requiresAuthentication: Bool {
        switch self {
        /// A guest has real settings of their own — see `Component/Settings` — so there is nothing
        /// to gate here, unlike `orderHistory` and the two saved lists below.
        case .catalog, .productDetails, .settings:
            return false
        /// Everything a shopper keeps. Orders, faves and the things they are waiting on all belong
        /// to somebody, so there is nothing to show a guest — and the prompt happens here, where
        /// the policy already lives, rather than being remembered by each screen.
        case .orderHistory, .allFaves, .allWaitlist, .allBackInStock:
            return true
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
        // ...one arm per remaining case, each to the container that owns the view
        }
    }
}
```

There is one `catalog` case, and not one case for each way to divide the shop, because `CatalogFilter` already states what the division is. A route for each filter would state that enumeration a second time. `ProductReference` exists because a caller that already holds the product can draw the screen with no second request, and a caller that holds only an id cannot. Both are the same destination.

The policy is in the enumeration and not in the screens. A guest can open the catalog, a product and their own settings. Everything that a shopper keeps — the order history, the faves, the waitlist and the back-in-stock list — belongs to a person, thus it needs an account. The switch is exhaustive. If you add a destination, the compiler makes you decide which group it is in, and does not leave a hole. Note that the two comments in the code carry the reason for each group, at the location where the policy is.

`makeView()` sends the construction to the UIDI container that owns the view. Thus view creation stays in the DI layer. Note that `ProductUIDI` supplies `.productDetails`, and not the feature that pushed it.

**[`iPhone/Navigation/Navigator.swift`](../iPhone/Navigation/Navigator.swift)**
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

`open` is the only entry, thus a new call site cannot go around the gate. This is the same principle as the authentication check in the wishlist use case rather than at each caller. `Account` has no `NavigationPath` of its own, because it is one screen with no push destinations. Thus the `push` and `pop` switches do not include it, and it carries no unused cases.

### Sequence of a navigation

1. The shopper taps a button in a `View`.
2. The `View` calls its navigation protocol, for example `SearchNavigation`. It calls its `ViewModel` for any side effects.
3. `Navigator` receives the call. `Navigator` conforms to each feature protocol, in `Destination.swift`, where the dependencies of the conformance are.
4. `Navigator.open()` applies the authentication gate if the destination needs it.
5. `push()` adds the `Destination` to the `NavigationPath` of the active tab. If the destination belongs to a different tab, it changes the tab first.
6. The `NavigationStack` of SwiftUI calls `.navigationDestination(for: Destination.self)`.
7. `Destination.makeView()` constructs the view through the UIDI container that owns it.

---

## Test strategy

> *"The Fragile Tests Problem: ...the system becomes rigid. Developers see that trivial changes to the system can cause massive test failures."*
> — Robert C. Martin, *Clean Architecture* (2017), Chapter 28

**Each component package has two test targets: a unit tier and an acceptance tier.** There is no separate target for the domain, the use cases or the repositories. A shopper never sees a repository. A shopper sees that the bag holds what they left in it, at the price that the shop quoted. The acceptance tier asserts that. The unit tier asserts the same rules in the language of the system, and names the unit that broke.

Each acceptance suite drives its feature through a **testing API**, which is Martin's own remedy for fragile tests. The testing API uses the language of the shopper.

**[`Component/Bag/Tests/BagAcceptanceTests/BeingToldWhatChangedTests.swift`](../Component/Bag/Tests/BagAcceptanceTests/BeingToldWhatChangedTests.swift)**
```swift
@Test("A shopper is told a price went up, and the bag is worth the new price")
func priceWentUp() async {
    let shopper = Shopper()
    shopper.choose(productId: 1, atPrice: 9.99)

    shopper.theShopNowSells(shopSells(1, at: 12.99))
    await shopper.comesBack()

    #expect(shopper.news.of(.priceWentUp, .priceWentDown) == [.priceWentUp(productId: pid(1), from: usd(9.99), to: usd(12.99))])
    #expect(shopper.bag.total == usd(12.99))
}
```

Every verb belongs to the shopper: `choose`, `theShopNowSells`, `comesBack`. The name of the test is the rule that it holds. [`Support/Shopper.swift`](../Component/Bag/Tests/BagAcceptanceTests/Support/Shopper.swift) supplies those verbs, and it is the only file in the suite that knows a repository exists.

No acceptance test names a repository, a store, a DTO or a `Default*UseCase`. You can rearrange the feature below these tests, and they continue to assert the same behaviour. That is the purpose of a testing API, and the reason that the layer tests it replaced were worth removal.

**The suites replace only what the application cannot own.** `Shopper` wires the real `BagDI` over a real `FileBagStore` in a temporary directory: a real repository, real DTOs and real JSON on a real disk. `Shop` fakes the catalog at the `HTTPClient` boundary. Thus the real client, the real decoding, the real repository and the real use cases all operate. `Account` uses the same `FakeAuthClient` that the application contains. Only the session is a stub, and each other component reads the session but never owns it.

That is not a preference of style. The first fault that this rewrite found was that one unreadable notice in a saved bag discarded the full bag of the shopper. No layer test found it, because no layer test went through real JSON.

| Suite | What it asserts |
| --- | --- |
| [`BagAcceptanceTests`](../Component/Bag/Tests/BagAcceptanceTests/UsingTheBagTests.swift) | Choosing, repricing, leaving and coming back, and everything the shop can change while a shopper is away |
| [`ProductAcceptanceTests`](../Component/Product/Tests/ProductAcceptanceTests/ShoppingTheCatalogTests.swift) | Browsing, paging, searching, categories, and every way the shop can fail to answer |
| [`SessionAcceptanceTests`](../Component/Session/Tests/SessionAcceptanceTests/GettingAnAccountTests.swift) | Signing up, signing in, what the form refuses, and staying signed in across launches |
| [`WishlistAcceptanceTests`](../Component/Wishlist/Tests/WishlistAcceptanceTests/SavingProductsTests.swift) | Saving, the heart on a card, and the account a list belongs to |
| [`SearchHistoryAcceptanceTests`](../Component/SearchHistory/Tests/SearchHistoryAcceptanceTests/SearchingAgainTests.swift) | Recent searches, whose they are, and what counts as a search |
| [`OrderAcceptanceTests`](../Component/Order/Tests/OrderAcceptanceTests/BuyingSomethingTests.swift) | Buying, what an order records, a declined payment, and coming back to what you bought |
| [`BagUIAcceptanceTests`](../UI/BagUI/Tests/BagUIAcceptanceTests/TheBagScreenTests.swift) | The bag screen: what it asks the shop, when, and what it shows while waiting |
| [`OrderUIAcceptanceTests`](../UI/OrderUI/Tests/OrderUIAcceptanceTests/BuyingFromAProductPageTests.swift) | Buy Now and checking out: what each one buys, what it leaves behind, and who it asks to sign in |
| [`WishlistUIAcceptanceTests`](../UI/WishlistUI/Tests/WishlistUIAcceptanceTests/KeepingAnEyeOnThingsTests.swift) | Both saved lists: filling them in, paging, and telling a dropped connection from a product that has gone |
| [`MoneyAcceptanceTests`](../Component/Money/Tests/MoneyAcceptanceTests/PayingForABasketTests.swift) | What a basket comes to, what three of a thing cost, and which way a half-penny goes |

**Why this is important.** A test that needs a simulator operates slowly, and fails for infrastructure reasons that have no relation to the logic under test. A test that needs a real network gives different results at different times. A design that uses protocols lets you assemble a full feature and drive it in the process, with the same result each time, in milliseconds. You need no third-party framework to make a double: a conforming struct is sufficient.

The UI packages other than `BagUI`, `HomeUI`, `OrderUI`, `ProductActionsUI`, `SettingsUI` and `WishlistUI` have no acceptance tier yet. The seams are in place; the tests are not.

---

## Module dependencies

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
├── HomeDI       ──▶  Home     ──▶  Product
├── SheetUIDI    ──▶  SheetUI
├── SnackbarUIDI ──▶  SnackbarUI
├── AuthUIDI     ──▶  AuthUI, Session, SheetUI
├── ProductActionsUIDI ──▶ ProductActionsUI ──▶ Wishlist, Bag, StockAlert, Product,
│                                              SnackbarUI, AuthUI
├── ProductUIDI  ──▶  ProductUI   ──▶  Product
│                ──▶  ProductActionsUIDI
├── HomeUIDI     ──▶  HomeUI      ──▶  Home, Product, Money, ProductUI
│                ──▶  WishlistUIDI, ProductActionsUIDI
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

The graph obeys these rules:

- No domain module depends on a UI module or a data module.
- No UI module depends on a `*Data` product. The UI reaches the domain and never the storage.
- A feature module depends on a **port** — `SnackbarUI`, `AuthUI`, `SheetUI` — and never on a host. Only the composition root links a `*UIDI` host product, and `AuthUIDI`, which is a host itself.
- A dependency across features or across components is permitted where the domain has a real relation. `Wishlist ──▶ Session`, because a shopper must have an account. `Bag ──▶ Product`, because a bag holds product ids and reads what the shop says about them. `SearchUI ──▶ ProductUI`, because a search result is a product card.
- The *domain* of `Bag` does not reach `Session` at all. Only `BagData` reaches it, and only to read who is signed in. The rules of the bag do not depend on a signed-in shopper, and the compiler now states that.
- The domain of `Order` *does* reach `Session`, and the difference is the point. A guest can hold a bag and cannot hold an order, thus to refuse an order is a business rule and not a storage detail.
- `OrderUI ──▶ Bag`, and never the opposite. The application gives `BagUI` a completed checkout button as an `AnyView`, in the same way that it gives a stock alert bell. Thus the payment stack stays out of the dependency list of each screen that draws a bag row or a heart. `ProductActionsUI` is free of checkout for the same reason.
- One `*UIDI` container can take another. `SearchUIDI` takes `BagUIDI`, thus a search result can carry an add-to-bag button. That is a view-construction dependency between equals and not a reach into the domain wiring of a component.
- `Networking` has no domain knowledge and is in `Library/`. `Money` was beside it and is not now: exact arithmetic and same-currency addition are the business's rules about prices, thus `Money` is a domain component that each other component can depend on.

Swift Package Manager and the compiler apply all of this. Convention does not.

---

## References

- Robert C. Martin, *Clean Architecture: A Craftsman's Guide to Software Structure and Design* (2017) — Prentice Hall
- Robert C. Martin, *Agile Software Development, Principles, Patterns, and Practices* (2002) — Prentice Hall
- Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software* (2003) — Addison-Wesley
- Martin Fowler, *Patterns of Enterprise Application Architecture* (2002) — Addison-Wesley
- Martin Fowler, [Inversion of Control Containers and the Dependency Injection Pattern](https://martinfowler.com/articles/injection.html) (2004)
- Mark Seemann & Steven van Deursen, *Dependency Injection: Principles, Practices, and Patterns* (2019) — Manning

---

## How to start

You need Xcode with the iOS 26 SDK. The packages target `.iOS(.v26)` and swift-tools 6.2.

1. Open `CleanArchitecture.xcodeproj`.
2. Build the `iPhone` scheme and run it.
3. Tap **Continue as Guest** to browse Home and Search immediately, against the real [DummyJSON](https://dummyjson.com) catalog.
4. Authentication occurs fully on the device. Create an account with any email address and password, then log in with the same data. If you tap the heart on a product while you are signed out, the application asks for an account and then completes the action.
5. A session stays valid for seven days and then expires. To log out before that, use the Account tab.

## License

For the conditions, see [LICENSE](../LICENSE).
