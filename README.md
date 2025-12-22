# Clean Architecture for iOS

A practical implementation of Clean Architecture principles in SwiftUI, demonstrating how to structure an iOS application with clear separation of concerns, testability, and maintainability.

## Overview

This project implements Clean Architecture as described by Robert C. Martin (Uncle Bob), organizing code into distinct layers with unidirectional dependencies. The architecture ensures that business logic remains independent of frameworks, UI, and external data sources.

## Architecture Principles

### The Dependency Rule

**Dependencies point inward.** Outer layers depend on inner layers, never the reverse. This ensures:

- Business logic has no dependencies on UI frameworks
- Domain layer is framework-agnostic
- External concerns (databases, APIs, UI) are isolated
- Each layer can be tested independently

### SOLID Principles

- **Single Responsibility**: Each class/module has one reason to change
- **Open/Closed**: Extend via protocols, not modification
- **Liskov Substitution**: Protocol implementations are interchangeable
- **Interface Segregation**: Focused, minimal protocols
- **Dependency Inversion**: Depend on abstractions, not concretions

## Project Structure

The project is organized into Swift Package Manager modules:

```
├── User/                    # Domain & Data layer
│   ├── User               # Domain entities, use cases, repository contracts
│   ├── UserData           # Repository implementations, data sources
│   └── UserDI             # Dependency injection for User module
├── LoginUI/                # Login feature module
├── HomeUI/                 # Home feature module
├── WishlistUI/             # Wishlist feature module
├── CartUI/                 # Cart feature module
└── iPhone/                 # Application layer (composition root)
    ├── Injector.swift      # Dependency injection container
    ├── Navigator.swift     # Navigation coordinator
    └── Main.swift          # App entry point
```

## Architecture Layers

```
┌─────────────────────────────────────┐
│     Application Layer                │ ← Composition Root
│  (iPhone/Injector, Navigator)       │   Wires everything together
├─────────────────────────────────────┤
│     Presentation Layer              │ ← UI & ViewModels
│  (FeatureUI modules)                 │   SwiftUI Views & ViewModels
├─────────────────────────────────────┤
│     Domain Layer                    │ ← Business Logic (Core)
│  (User/User module)                 │   Entities, Use Cases, Contracts
├─────────────────────────────────────┤
│     Data Layer                      │ ← External Interfaces
│  (User/UserData module)             │   Repositories, Data Sources
└─────────────────────────────────────┘
```

## Domain Layer

The domain layer (`User/User`) contains pure business logic with **zero dependencies** on external frameworks.

### Entities

Core business objects representing domain concepts. Framework-independent and reusable.

**File**: [`User/Sources/Domain/Model/User.swift`](User/Sources/Domain/Model/User.swift)

```swift
public struct User: Equatable, Sendable {
    public let id: UUID
    public let username: String
}
```

### Use Cases

Single-purpose classes that orchestrate business operations. Each use case represents one specific business action.

**File**: [`User/Sources/Domain/UseCases/UserLoginUseCase.swift`](User/Sources/Domain/UseCases/UserLoginUseCase.swift)

```swift
public protocol UserLoginUseCase {
    @MainActor
    func execute(username: String, password: String) async -> Result<Void, LoginError>
}
```

**Additional Use Cases**:
- `UserIsLoggedInUseCase` - Checks if user is logged in
- `ObserveUserIsLoggedInUseCase` - Observes login state changes

### Repository Contracts

Abstract interfaces defining how the domain accesses data, without implementation details.

**File**: [`User/Sources/Domain/Repository/UserRepository.swift`](User/Sources/Domain/Repository/UserRepository.swift)

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

## Data Layer

The data layer (`User/UserData`) implements repository contracts and handles all external data concerns.

### Repository Implementation

Concrete implementations coordinate between data sources, map DTOs to domain entities, and handle error translation.

**File**: [`User/Sources/Data/DefaultUserRepository.swift`](User/Sources/Data/DefaultUserRepository.swift)

```swift
public final class DefaultUserRepository: UserRepository {
    private let session: UserSession
    private let authClient: AuthClient
    
    // Implements UserRepository protocol
    // Maps AuthClient errors to domain LoginError
    // Manages user session state
}
```

### Data Sources

Data sources handle data from a single source (API, database, cache, session).

**File**: [`User/Sources/Data/Auth/AuthClient.swift`](User/Sources/Data/Auth/AuthClient.swift)

```swift
public protocol AuthClient: Sendable {
    func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
```

**File**: [`User/Sources/Data/Session/UserSession.swift`](User/Sources/Data/Session/UserSession.swift)

```swift
@MainActor
public protocol UserSession: AnyObject {
    var user: User? { get }
    var isLoggedInPublisher: AnyPublisher<Bool, Never> { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}
```

## Presentation Layer

The presentation layer handles user interface and interactions using the MVVM pattern. Each feature is organized as an independent module.

### Feature Module Structure

Each feature module follows this structure:
```
FeatureUI/
├── Sources/
│   ├── UI/                    # Views and ViewModels
│   ├── Navigation/            # Navigation protocol
│   └── DI/                    # Feature DI container
└── Tests/
```

### ViewModels

ViewModels are observable classes that manage UI state and coordinate with use cases.

**File**: [`LoginUI/Sources/UI/LoginScreen/LoginScreenViewModel.swift`](LoginUI/Sources/UI/LoginScreen/LoginScreenViewModel.swift)

```swift
@MainActor
public final class LoginScreenViewModel: ObservableObject {
    private let userLogin: UserLoginUseCase
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    func login() async { /* coordinates with use case */ }
}
```

### Views

Views are pure UI components that display data and delegate actions.

**File**: [`LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift`](LoginUI/Sources/UI/LoginScreen/LoginScreenView.swift)

```swift
public struct LoginScreenView: View {
    @ObservedObject var viewModel: LoginScreenViewModel
    // Displays UI and delegates actions to ViewModel
}
```

### Feature DI Containers

Each feature has a DI container that creates ViewModels and Views. Navigation-based features receive navigation protocols; domain-based features receive domain DI containers.

**File**: [`LoginUI/Sources/DI/LoginUIDI.swift`](LoginUI/Sources/DI/LoginUIDI.swift)

```swift
public struct LoginUIDI {
    private let userDI: UserDI
    func loginView() -> some View { /* creates LoginScreenView */ }
}
```

**File**: [`HomeUI/Sources/DI/HomeUIDI.swift`](HomeUI/Sources/DI/HomeUIDI.swift)

```swift
public struct HomeUIDI {
    private let navigation: HomeNavigation
    func mainView() -> some View { /* creates HomeScreenView */ }
    func detailView(id: UUID) -> some View { /* creates detail view */ }
}
```

## Application Layer

The application layer (`iPhone/`) wires everything together and manages app-level concerns. This is the composition root where dependency injection and navigation coordination happen.

### Dependency Injection Container

The `Injector` is the composition root that wires all layers together.

**File**: [`iPhone/Injector.swift`](iPhone/Injector.swift)

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
    // Initializes all dependencies
}
```

### Domain DI Container

The `UserDI` container wires domain dependencies together.

**File**: [`User/Sources/DI/UserDI.swift`](User/Sources/DI/UserDI.swift)

```swift
public struct UserDI {
    public let userLoginUseCase: UserLoginUseCase
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase
    // Creates data sources, repositories, and use cases
}
```

### App Entry Point

The app entry point coordinates the initial view based on authentication state.

**File**: [`iPhone/Main/Main.swift`](iPhone/Main/Main.swift)

```swift
@main
struct Main: App {
    @StateObject private var viewModel = MainViewModel(...)
    // Switches between login and main app based on auth state
}
```

## Navigation Architecture

The navigation system decouples features while maintaining type safety through a multi-layered approach.

### Components

1. **Feature Navigation Protocols**: Each feature defines what navigation it needs
2. **Navigator**: Central coordinator that implements all navigation protocols
3. **Destination Enum**: Centralized destination types with view factories

### Feature Navigation Protocols

Each feature defines its navigation requirements through a protocol.

**File**: [`HomeUI/Sources/Navigation/HomeNavigation.swift`](HomeUI/Sources/Navigation/HomeNavigation.swift)

```swift
public protocol HomeNavigation: AnyObject {
    func openHomeDetail(id: UUID)
    func goToWishlistDetail(id: UUID)
}
```

### Navigator

The Navigator manages tab state, navigation paths, and view factories. It implements all navigation protocols via extensions.

**File**: [`iPhone/Navigation/Navigator.swift`](iPhone/Navigation/Navigator.swift)

```swift
@MainActor
final class Navigator: ObservableObject {
    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    @Published var cartPath = NavigationPath()
    
    func push(_ route: any Hashable, tab: Tabs? = nil) { /* ... */ }
    func view(for route: Any) -> AnyView? { /* ... */ }
}

extension Navigator: HomeNavigation, WishlistNavigation, CartNavigation {
    // Implements all navigation protocol methods
}
```

### Destination Enum

Centralized destination types with view factories that delegate to UIDI containers.

**File**: [`iPhone/Navigation/Destination.swift`](iPhone/Navigation/Destination.swift)

```swift
public enum Destination: Hashable {
    case homeDetail(id: UUID)
    case wishlistDetail(id: UUID)
    case cartDetail(id: UUID)
    
    func makeView() -> some View {
        // Delegates to appropriate UIDI container
    }
}
```

### Navigation Flow

1. User action in View → ViewModel method called
2. ViewModel calls navigation protocol method
3. Navigator (implements protocol) receives call
4. Navigator.push() adds destination to NavigationPath
5. SwiftUI NavigationStack detects path change
6. Navigator.view() looks up factory for destination
7. Destination.makeView() delegates to UIDI container
8. UIDI.detailView() creates and returns view
9. View is displayed

## Testing Strategy

Each layer can be tested in isolation using mocks:

- **Domain**: Test use cases with mock repositories
- **Data**: Test repositories with mock data sources
- **Presentation**: Test ViewModels with mock use cases

Protocol-based design makes mocking straightforward at every layer. See test files in each module's `Tests/` directory.

## Benefits

- **Maintainability**: Clear layer boundaries, easy to locate code, isolated changes
- **Testability**: Each layer testable in isolation with straightforward mocking
- **Scalability**: Established patterns, centralized dependencies, code reuse
- **Team Collaboration**: Parallel work on different layers, clear contracts
- **Platform Independence**: Business logic shareable, framework-agnostic core

## Module Dependencies

```
iPhone (App)
├── UserDI
│   ├── User (Domain)
│   └── UserData
│       └── User (Domain)
├── LoginUIDI
│   ├── LoginUI
│   └── UserDI
├── HomeUIDI
│   └── HomeUI
├── WishlistUIDI
│   └── WishlistUI
└── CartUIDI
    └── CartUI

Navigator
└── All Feature UIDI modules (via Destination)
```

## Getting Started

1. Open `CleanArchitecture.xcodeproj` in Xcode
2. Build and run the `iPhone` scheme
3. Explore the code following the layer structure described above

## License

See [LICENSE](LICENSE) file for details.
