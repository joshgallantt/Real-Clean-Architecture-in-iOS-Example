# Clean Architecture Guide for iOS

This guide explains Clean Architecture patterns and principles using a practical iOS implementation. Clean Architecture, popularized by Robert C. Martin (Uncle Bob), organizes code into layers with clear dependencies and responsibilities, making applications more maintainable, testable, and scalable.

## Core Principles (SOLID)

Clean Architecture is built upon the SOLID principles of object-oriented design:

### 1. **Single Responsibility Principle (SRP)**
Each class should have only one reason to change. In Clean Architecture, this means each layer and component has a single, well-defined responsibility.

### 2. **Open/Closed Principle (OCP)**
Software entities should be open for extension but closed for modification. Use protocols and dependency injection to extend behavior without changing existing code.

### 3. **Liskov Substitution Principle (LSP)**
Objects should be replaceable with instances of their subtypes. Any implementation of a protocol should be substitutable without breaking functionality.

### 4. **Interface Segregation Principle (ISP)**
Clients shouldn't be forced to depend on interfaces they don't use. Create focused, specific protocols rather than large, monolithic ones.

### 5. **Dependency Inversion Principle (DIP)**
High-level modules shouldn't depend on low-level modules. Both should depend on abstractions. This is the foundation of the Dependency Rule in Clean Architecture.

## Clean Architecture Rules

### **The Dependency Rule**
Dependencies point inward. Outer layers depend on inner layers, never the reverse. This enforces the Dependency Inversion Principle at an architectural level.


### **Independence**
Business rules don't depend on UI, databases, or external frameworks, achieved through proper abstraction and dependency inversion.

## Architecture Layers

```
┌─────────────────────────────────────┐
│     Application Layer               │ ← Composition Root
│  (Dependency Injection)             │
├─────────────────────────────────────┤
│     Presentation Layer              │ ← UI & ViewModels
│   (Views & ViewModels)              │
├─────────────────────────────────────┤
│     Domain Layer                    │ ← Business Logic
│  (Use Cases & Entities)             │   (Core)
├─────────────────────────────────────┤
│     Data Layer                      │ ← External Interfaces
│ (Repositories & Data Sources)       │
└─────────────────────────────────────┘
```

---

## Domain Layer (The Core)

The Domain Layer contains your business logic and is the heart of Clean Architecture. It has **no dependencies** on external frameworks, UI, or data persistence.

### Entities

**What they are**: Core business objects that represent your domain concepts.

**Example**: `User.swift`
```swift
public struct User: Equatable, Sendable {
    public let id: UUID
    public let username: String
}
```

**Why they matter**:
- Encapsulate business rules and data
- Framework-independent
- Can be shared across different applications

### Use Cases (Interactors)

**What they are**: Single-purpose classes that orchestrate business operations. Each use case represents one specific business action.

**Example**: `UserLoginUseCase.swift`
```swift
public protocol UserLoginUseCase {
    func execute(username: String, password: String) async -> Result<Void, LoginError>
}

public struct DefaultUserLoginUseCase: UserLoginUseCase {
    let userRepository: UserRepository
    
    public func execute(username: String, password: String) async -> Result<Void, LoginError> {
        // Business rule: Validate inputs
        if username.isEmpty { return .failure(.usernameIsEmpty) }
        if password.isEmpty { return .failure(.passwordIsEmpty) }
        
        // Delegate data operations to repository
        return await userRepository.login(username: username, password: password)
    }
}
```

**Key Patterns**:
- **Single Responsibility**: Each use case does one thing
- **Dependency Injection**: Receives repositories through constructor
- **Domain Errors**: Returns business-specific error types
- **Protocol-Based**: Defined by interfaces, not implementations

**Benefits**:
- Business logic is isolated and testable
- Easy to understand what the system can do
- Can be reused across different UIs

### Repository Contracts

**What they are**: Abstract interfaces that define how the domain layer accesses data, without knowing the implementation details.

**Example**: `UserRepository.swift`
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

**Why they're important**:
- **Dependency Inversion**: Domain defines what it needs, doesn't depend on implementation
- **Testability**: Easy to create mock implementations
- **Flexibility**: Can swap data sources without changing business logic

---

## Data Layer (External Interface)

The Data Layer implements the repository contracts and handles all external data concerns.

### Repository Implementations

**What they are**: Concrete implementations of repository contracts that coordinate between different data sources.

**Example**: `DefaultUserRepository.swift`
```swift
public final class DefaultUserRepository: UserRepository {
    private let session: UserSession
    private let authClient: AuthClient
    
    public func login(username: String, password: String) async -> Result<Void, LoginError> {
        let result = await authClient.login(username: username, password: password)
        switch result {
        case let .success((user, token)):
            // Map DTO (AuthToken) to domain usage and store domain entity (User)
            session.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            // Map data layer errors to domain errors
            return .failure(mapAuthClientErrorToLoginError(error))
        }
    }
    
    private func mapAuthClientErrorToLoginError(_ error: AuthClientError) -> LoginError {
        switch error {
        case .invalidCredentials: return .invalidCredentials
        case .networkFailure, .unknown: return .unknown
        }
    }
}
```

**Key Responsibilities**:
- **Coordination**: Orchestrate between different data sources
- **Data Mapping**: Convert DTOs to domain entities and data layer errors to domain errors
- **Business Rule Enforcement**: Apply domain-specific validation and constraints
- **Caching**: Manage data consistency between local and remote sources

### Data Sources

**What they are**: Specific implementations that handle data from a single source (API, database, cache).

**Example**: `AuthClient.swift`
```swift
public protocol AuthClient: Sendable {
    func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError>
}

public actor FakeAuthClient: AuthClient {
    public func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError> {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Business validation
        guard !username.isEmpty, !password.isEmpty else {
            return .failure(.invalidCredentials)
        }
        
        // Return success with mock data
        let token = AuthToken(value: UUID().uuidString, expiresAt: Date().addingTimeInterval(3600))
        return .success((User(id: UUID(), username: username), token))
    }
}
```

**Types of Data Sources**:
- **API Clients**: Handle HTTP requests
- **Database Access**: Local persistence (Core Data, SQLite)
- **Cache Managers**: In-memory or disk caching
- **Session Storage**: User session and authentication state

### Data Transfer Objects (DTOs)

**What they are**: Objects that represent data structure from external sources, separate from domain entities.

**Example**: `AuthToken.swift`
```swift
public struct AuthToken: Equatable, Sendable {
    public let value: String
    public let expiresAt: Date
    
    public var isExpired: Bool {
        Date() >= expiresAt
    }
}
```

**Why separate from entities**:
- External APIs might change their structure without affecting domain logic
- Domain entities represent business concepts, DTOs represent external data format
- Repositories handle the mapping between DTOs and domain entities
- Allows for data transformation, validation, and format conversion

---

## Presentation Layer (UI)

The Presentation Layer handles user interface and user interactions using the MVVM pattern.

### ViewModels

**What they are**: Observable classes that manage UI state and coordinate with use cases.

**Example**: `LoginScreenViewModel.swift`
```swift
@MainActor
public final class LoginScreenViewModel: ObservableObject {
    // UI State
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Use Case Dependency
    private let userLogin: UserLoginUseCase
    
    func login() async {
        isLoading = true
        defer { isLoading = false }
        
        // Call use case
        let result = await userLogin.execute(username: username, password: password)
        
        // Handle result and update UI state
        switch result {
        case .success:
            error = nil
        case .failure(let loginError):
            error = mapLoginErrorToMessage(loginError)
        }
    }
}
```

**Key Patterns**:
- **Observable**: Uses `@Published` for reactive UI updates
- **State Management**: Manages all UI-related state
- **Use Case Coordination**: Calls business logic, doesn't implement it
- **Error Handling**: Converts domain errors to user-friendly messages

### Views (SwiftUI)

**What they are**: Pure UI components that display data and delegate actions to ViewModels.

**Example**: `LoginScreenView.swift`
```swift
public struct LoginScreenView: View {
    @ObservedObject var viewModel: LoginScreenViewModel
    
    public var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $viewModel.username)
            SecureField("Password", text: $viewModel.password)
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Login") {
                    Task { await viewModel.login() }
                }
            }
            
            if let error = viewModel.error {
                Text(error).foregroundColor(.red)
            }
        }
    }
}
```

**Principles**:
- **No Business Logic**: Views only handle presentation
- **Reactive**: Automatically update when ViewModel state changes
- **Declarative**: Describe what the UI should look like

---

## Application Layer (Composition Root)

The Application Layer wires everything together and manages app-level concerns.

### Dependency Injection Container

**What it is**: A central place where all dependencies are created and configured.

**Example**: `Injector.swift`
```swift
final class Injector {
    static let shared = Injector()
    
    // Domain Dependencies
    private let userDI: UserDI
    
    // Navigation
    let appNavigator: Navigator
    private let homeNavigation: DefaultHomeNavigation
    
    private init() {
        // Create domain layer
        userDI = UserDI()
        
        // Create navigation
        appNavigator = Navigator()
        homeNavigation = DefaultHomeNavigation(navigator: appNavigator)
        
        // Create UI layers
        loginUIDI = LoginUIDI(userDI: userDI)
        homeUIDI = HomeUIDI(navigation: homeNavigation)
    }
}
```

**Benefits**:
- **Single Configuration Point**: All dependencies wired in one place
- **Dependency Control**: Easy to swap implementations for testing
- **Object Lifecycle**: Manages singleton vs transient instances

### Navigation Contracts

**What they are**: Protocols that define navigation capabilities without coupling features together.

**Example**: `HomeNavigation.swift`
```swift
public protocol HomeNavigation: AnyObject {
    func openHomeDetail(id: UUID)
    func goToWishlistDetail(id: UUID)
}

// Implementation in App layer
final class DefaultHomeNavigation: HomeNavigation {
    private unowned let navigator: Navigator
    
    func openHomeDetail(id: UUID) {
        navigator.push(HomeDestination.detail(id: id), tab: .home)
    }
    
    func goToWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }
}
```

**Key Benefits**:
- **Decoupling**: Features don't know about other features directly
- **Testability**: Easy to mock navigation for testing
- **Type Safety**: Navigation parameters are compile-time checked

### Navigator Pattern

**What it is**: A centralized navigation coordinator that manages app-wide navigation state.

**Example**: `Navigator.swift`
```swift
final class Navigator: ObservableObject {
    @Published var selectedTab: Tabs = .home
    @Published var homePath = NavigationPath()
    @Published var wishlistPath = NavigationPath()
    
    // Type-safe destination registry
    private var factories: [ObjectIdentifier: (Any) -> AnyView] = [:]
    
    public func register<Route: Hashable>(factory: @escaping (Route) -> some View) {
        let key = ObjectIdentifier(Route.self)
        factories[key] = { any in
            guard let route = any as? Route else { return AnyView(EmptyView()) }
            return AnyView(factory(route))
        }
    }
    
    func push(_ route: any Hashable, tab: Tabs? = nil) {
        // Navigation logic...
    }
}
```

**Features**:
- **Type Safety**: Routes are strongly typed enums
- **State Management**: Manages navigation stack for each tab
- **Cross-Tab Navigation**: Can navigate between different sections
- **View Factory**: Dynamically creates views for routes

---

## Feature Module Pattern

Each feature is organized as an independent module with consistent structure:

### Module Structure
```
FeatureUI/
├── Sources/
│   ├── UI/
│   │   ├── FeatureScreen/
│   │   ├── Navigation/
│   │   └── Details/
│   └── DI/
│       └── FeatureUIDI.swift
├── Tests/
└── Package.swift
```

### Feature DI Container

**What it is**: A dependency injection container specific to one feature.

**Example**: `HomeUIDI.swift`
```swift
public struct HomeUIDI {
    private let navigation: HomeNavigation
    
    public init(navigation: HomeNavigation) {
        self.navigation = navigation
    }
    
    @MainActor
    public func mainView() -> some View {
        let viewModel = HomeScreenViewModel()
        return HomeScreenView(viewModel: viewModel, navigation: navigation)
    }
    
    @MainActor
    public func makeView(for destination: HomeDestination) -> some View {
        switch destination {
        case .detail(let id):
            HomeDetailScreenView(id: id)
        }
    }
}
```

**Benefits**:
- **Feature Isolation**: Each feature manages its own dependencies
- **Independent Development**: Features can be developed separately
- **Consistent API**: All features expose similar interfaces

---

## Testing Strategy

### Domain Layer Testing
```swift
// Test use cases with mock repositories
func testLoginWithEmptyUsername() async {
    let mockRepository = MockUserRepository()
    let useCase = DefaultUserLoginUseCase(userRepository: mockRepository)
    
    let result = await useCase.execute(username: "", password: "password")
    
    XCTAssertEqual(result, .failure(.usernameIsEmpty))
}
```

### Data Layer Testing
```swift
// Test repository implementations with mock data sources
func testLoginSuccess() async {
    let mockAuthClient = MockAuthClient()
    let mockSession = MockUserSession()
    let repository = DefaultUserRepository(session: mockSession, authClient: mockAuthClient)
    
    let result = await repository.login(username: "user", password: "pass")
    
    XCTAssertEqual(result, .success(()))
}
```

### Presentation Layer Testing
```swift
// Test ViewModels with mock use cases
@MainActor
func testLoginLoading() async {
    let mockUseCase = MockUserLoginUseCase()
    let viewModel = LoginScreenViewModel(userLogin: mockUseCase)
    
    await viewModel.login()
    
    XCTAssertFalse(viewModel.isLoading)
}
```

---

## Benefits of This Architecture

### 1. **Maintainability**
- Clear boundaries between layers
- Easy to locate and modify code
- Changes in one layer don't ripple through others

### 2. **Testability**
- Each layer can be tested in isolation
- Mock implementations are straightforward
- Business logic is pure and predictable

### 3. **Scalability**
- New features follow established patterns
- Dependencies are managed centrally
- Code reuse across features

### 4. **Team Collaboration**
- Different teams can work on different layers
- Clear contracts between components
- Consistent patterns across the codebase

### 5. **Platform Independence**
- Business logic can be shared between platforms
- Easy to create different UIs for the same logic
- Framework changes don't affect core business rules
