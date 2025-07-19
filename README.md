# Clean Architecture iOS Template

A production-grade starter template for SwiftUI apps, built with Clean Architecture, SOLID principles, and strict Swift 5.9+ concurrency. Each feature is isolated, navigation is registry-driven, and everything is testable by default.

---

## Table of Contents

* [Overview](#overview)
* [Project Structure](#project-structure)
* [Architecture Breakdown](#architecture-breakdown)

  * [SOLID in Practice (Swift snippets)](#solid-in-practice-swift-snippets)
  * [Dependency Injection & The Injector](#dependency-injection--the-injector)
  * [Navigation Registry & Tab Management](#navigation-registry--tab-management)
  * [Root Layer & Authentication Flow](#root-layer--authentication-flow)
  * [Feature Module Example](#feature-module-example)
* [Adding a New Feature](#adding-a-new-feature)
* [Getting Started](#getting-started)
* [Resources](#resources)
* [License](#license)

---

## Overview

* **Feature-first:** Each business area is a self-contained module (domain, data, DI, UI).
* **Centralized, protocol-driven navigation:** Navigation is injected and managed at app launch, never inside UI or feature modules.
* **Authentication-first root:** The root observes authentication state and automatically switches between login and main UI.
* **100% SOLID:** Every layer is protocol-oriented for maximal testability and decoupling.
* **Strict concurrency:** Designed for Swift 5.9+ concurrency enforcement.
* **Package-by-component:** Every feature (Home, Cart, Wishlist, etc) lives as a Swift Package at the repo root for clear boundaries, independent builds, and testability.

---

## Project Structure

```plaintext
├── App/                     # App entrypoint, navigation, DI, root-level composition
│   ├── Boot.swift
│   ├── Injector.swift
│   └── Navigation/
│   └── Root/
├── AppTests/                # App-level unit and UI tests
├── User/                    # User domain module (domain, data, DI)
├── HomeUI/                  # Home feature module (DI, Presentation)
├── CartUI/                  # Cart feature module (DI, Presentation)
├── WishlistUI/              # Wishlist feature module (DI, Presentation)
├── LoginUI/                 # Login feature module (DI, Presentation)

```

**Each feature package contains:**

* `Sources/Domain`: Business logic, models, protocols.
* `Sources/Data`: Repositories, service clients.
* `Sources/DI`: DI container for the feature.
* `Sources/Presentation`: Views, ViewModels, navigation contracts.
* `Tests/`: Given\_When\_Then test targets per feature.

**Example File Layout:**

```plaintext
HomeUI/
├── Package.swift
├── Sources/
│   ├── DI/
│   │   └── HomeUIDI.swift
│   └── Presentation/
│       ├── HomeScreen/
│       │   ├── HomeScreenView.swift
│       │   └── HomeScreenViewModel.swift
│       ├── Navigation/
│       │   ├── HomeNavigation.swift
│       │   └── HomeDestination.swift
│       └── HomeDetails/
│           └── HomeDetailScreenView.swift
└── Tests/
    └── HomeUITests/
        └── HomeUITests.swift
```

---

## Architecture Breakdown

Absolutely, here’s an improved README section with concise explanations and Swift-centric context, keeping it clear and practical for other iOS devs:

---

### SOLID Principles in Practice

SOLID is a set of five principles for writing maintainable, testable, and scalable code. Each principle helps structure your codebase so it’s easier to extend, refactor, and reason about—especially as your project grows.

| Principle | How it’s applied in Swift       |
| --------- | ------------------------------- |
| SRP       | Single-purpose types, modules   |
| OCP       | New features via extension      |
| LSP       | Protocol conformance everywhere |
| ISP       | Lean, client-focused protocols  |
| DIP       | All wiring via abstractions     |

#### SRP (Single Responsibility Principle)

A type should do one thing well, and only one thing. This makes your code easier to test, maintain, and reason about.

```swift
// UserLoginUseCase is only responsible for login.
struct UserLoginUseCase {
    let repository: UserRepository

    func execute(email: String, password: String) async throws -> User {
        try await repository.login(email: email, password: password)
    }
}
```

#### OCP (Open/Closed Principle)

Code should be open for extension but closed for modification. Add new functionality by conforming to protocols or extending types—don’t modify existing code.

```swift
struct MockUserRepository: UserRepository {
    func login(email: String, password: String) async throws -> User { User(email: email) }
    func register(email: String, password: String) async throws -> User { User(email: email) }
}
```

#### LSP (Liskov Substitution Principle)

You should be able to use any conforming type in place of its protocol without breaking your code.

```swift
protocol CartNavigation {
    func openCartDetail(id: UUID)
}
final class CartNavigator: CartNavigation { /* ... */ }
final class TestCartNavigator: CartNavigation { /* ... */ }
```

#### ISP (Interface Segregation Principle)

Define focused, client-specific protocols instead of bloated ones, so each conformer only implements what it actually needs.

```swift
protocol WishlistNavigation {
    func openWishlistDetail(id: UUID)
    func goToCartDetail(id: UUID)
}
```

#### DIP (Dependency Inversion Principle)

Depend on abstractions (protocols), not concrete implementations. This enables loose coupling, testability, and flexible wiring.

```swift
final class Injector {
    private let userRepository: UserRepository
    private let userLoginUseCase: UserLoginUseCase

    init() {
        userRepository = DefaultUserRepository()
        userLoginUseCase = UserLoginUseCase(repository: userRepository)
    }
}
```

---

### Dependency Injection & The Injector

* **Singleton Injector** composes all dependencies at startup.
* No ViewModel or feature creates its own dependencies—everything is injected.
* Swap or mock any dependency by updating the Injector.

```swift
final class Injector {
    static let shared = Injector()
    // ... component and navigator setup ...
    private init() { /* ... */ }
}
```

---

### Navigation Registry & Tab Management

* **Destinations registered at app launch:** Each feature route is mapped to a view factory.
* **Navigator protocols push routes:** Features never manage navigation stacks directly.
* **TabView hosts a stack per tab.** Switching tabs resets navigation as needed.

```swift
extension Navigation {
    static func registerAllDestinations(using injector: Injector) {
        let appNavigator = injector.appNavigator
        appNavigator.register { (destination: HomeDestination) in
            injector.homeUIDI.makeView(for: destination)
        }
        // ... repeat for Wishlist, Cart ...
    }
}
```

**Features receive only navigator protocols:**

```swift
final class WishlistNavigator: WishlistNavigation {
    private unowned let navigator: Navigation

    func openWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }
}
```

---

### Root Layer & Authentication Flow

* **RootScreenViewModel** observes user authentication and switches between login and main UI tabs.
* **RootUIDI** composes login, main tabs, and injects all feature UI modules.

```swift
struct RootScreenView: View {
    @ObservedObject var viewModel: RootScreenViewModel
    let loginView: AnyView
    let tabView: AnyView

    var body: some View {
        switch viewModel.path {
        case .login: loginView
        case .main:  tabView
        }
    }
}
```

```swift
final class RootScreenViewModel: ObservableObject {
    @Published var path: RootDestination
    private var cancellable: AnyCancellable?
    private let observeUserLoggedIn: ObserveUserIsLoggedInUseCaseProtocol

    init(...) {
        cancellable = observeUserLoggedIn.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggedIn in
                self?.path = loggedIn ? .main : .login
            }
    }
}
```

---

### Feature Module Example

* **Domain:** protocols, use cases
* **Data:** implementations
* **DI:** composition and UI injection
* **UI:** SwiftUI views and ViewModels

**Feature navigation is protocol-driven and injected:**

```swift
protocol HomeNavigation {
    func openHomeDetail(id: UUID)
    func goToWishlistDetail(id: UUID)
}

final class HomeNavigator: HomeNavigation {
    private unowned let navigator: Navigation

    func openHomeDetail(id: UUID) {
        navigator.push(HomeDestination.detail(id: id), tab: .home)
    }
}
```

**ViewModels and Views only get what they need:**

```swift
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
}
```

---

## Adding a New Feature

1. Create a module at the repo root.
2. Define your domain protocols and use cases.
3. Implement repositories/data sources.
4. Create navigator protocols and destination enums.
5. Implement your navigator and register it in `Navigation+registerAllDestinations.swift`.
6. Create a `FeatureUIDI` entry point for feature UI composition.
7. Inject via `Injector.swift`.

---

## Getting Started

* Requires **Xcode 15+** and **Swift 5.9+**.
* App boots from `Boot.swift`, registers destinations, and builds the DI graph via `Injector.swift`.
* The root layer manages authentication and tabbed navigation.
* All features are modular—follow the pattern above to add more.

---

## Resources

* [Denis Brandi: Android Clean Architecture Example](https://github.com/DenisBronx/Real-Clean-Architecture-In-Android---Sample)
* [The Clean Architecture (Uncle Bob)](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Clean Swift (iOS Focused)](https://clean-swift.com/clean-swift-ios-architecture/)
* [Clean Architecture in iOS (Essential Developer)](https://www.essentialdeveloper.com/articles/clean-architecture-in-ios/)

---

## License

MIT. Fork, use, or adapt for any project. Attribution required.
