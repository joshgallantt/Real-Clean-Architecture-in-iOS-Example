# Clean Architecture iOS Template

A robust, production-ready template for SwiftUI apps, architected around Clean Architecture, SOLID principles, and strict Swift 5.9+ concurrency. Each feature is isolated, navigation is registry-driven, and everything is testable by default.

---

## Contents

* [Overview](#overview)
* [Project Structure](#project-structure)
* [Clean Architecture Principles](#clean-architecture-principles)
* [SOLID in Practice (with Swift snippets)](#solid-in-practice-with-swift-snippets)
* [Dependency Injection & The Injector](#dependency-injection--the-injector)
* [Navigation Registry & Tab Management](#navigation-registry--tab-management)
* [Root Layer & Authentication Flow](#root-layer--authentication-flow)
* [Feature Module Example](#feature-module-example)
* [Adding a New Feature](#adding-a-new-feature)
* [Getting Started](#getting-started)
* [Getting Started](#resources)
* [License](#license)

---

## Overview

* **Feature-first:** Each business area is a self-contained module (domain, data, DI, UI).
* **Centralized, protocol-driven navigation:** No navigation code in feature modules or UI—everything flows through injected navigators and a destination registry.
* **Authentication-first root:** The root observes authentication and switches between login and main UI tabs automatically.
* **100% SOLID:** Every layer uses protocol-oriented programming for max testability and swappability.
* **Strict concurrency:** Designed for Swift 5.9+.

---

## Project Structure

```plaintext
├── Application/         # App entry, dependency injection graph (DI)
├── Navigation/          # Tab/feature navigators, destination registry
├── Root/                # Auth observer, root screen, tab UI composition
├── Component/           # Features: domain, data, DI, UI per module
```

| Layer       | Role                                | Example Files                                 |
| ----------- | ----------------------------------- | --------------------------------------------- |
| Application | Launch, DI graph                    | Boot.swift, Injector.swift                    |
| Navigation  | Navigator protocols, tab navigation | HomeNavigator.swift, CartNavigator.swift, ... |
| Root        | Auth state, login/tab switcher      | RootUIDI.swift, RootScreenView\.swift, ...    |
| Component   | Feature modules (Home, Cart, etc)   | Home/, Cart/, Wishlist/, User/, ...           |

---

## Clean Architecture Principles

**Clean Architecture** separates business logic, data, UI, and navigation.
Here’s how the layers work:

* **Domain:** Pure business logic and protocols, no frameworks.
* **Data:** Implements repositories, talks to local/remote data sources.
* **Presentation:** SwiftUI views, ViewModels, and UI DI. No business logic, no navigation logic.
* **Navigation:** All navigation is via injected navigators and a destination registry.
* **Root/Application:** Bootstraps the DI graph, wires up the main UI and authentication observer.

**Why this matters:**

* Swap any implementation (UI, data, navigation) with no effect on business logic.
* Write pure Swift unit tests for all core flows.
* Easily onboard new devs to a single feature without full context.

---

## SOLID in Practice (with Swift snippets)

| Principle | How it's applied in this codebase                   |
| --------- | --------------------------------------------------- |
| SRP       | Each type/class/module has a single responsibility  |
| OCP       | New flows/features are added, never modify core     |
| LSP       | Any conformer to a protocol can be swapped anywhere |
| ISP       | Protocols are lean, only what consumers need        |
| DIP       | All wiring uses abstractions, never concrete types  |

### SRP: Single Responsibility Principle

```swift
// UserLoginUseCase is only responsible for login, nothing else.
struct UserLoginUseCase {
    let repository: UserRepository

    func execute(email: String, password: String) async throws -> User {
        try await repository.login(email: email, password: password)
    }
}
```

---

### OCP: Open/Closed Principle

```swift
// Add new repository implementations freely.
struct MockUserRepository: UserRepository {
    func login(email: String, password: String) async throws -> User { User(email: email) }
    func register(email: String, password: String) async throws -> User { User(email: email) }
}

// Use DI to inject the implementation—no core code changes required.
let repo: UserRepository = useMocks ? MockUserRepository() : DefaultUserRepository()
let useCase = UserLoginUseCase(repository: repo)
```

---

### LSP: Liskov Substitution Principle

```swift
protocol CartNavigation {
    func openCartDetail(id: UUID)
}

final class CartNavigator: CartNavigation { /* ... */ }
final class TestCartNavigator: CartNavigation {
    func openCartDetail(id: UUID) { /* record calls for tests */ }
}

// Swap any CartNavigation in DI, no need to change the consumer.
let nav: CartNavigation = isTesting ? TestCartNavigator() : CartNavigator(navigator: appNavigator)
```

---

### ISP: Interface Segregation Principle

```swift
// Protocol exposes only the navigation actions needed for Wishlist.
protocol WishlistNavigation {
    func openWishlistDetail(id: UUID)
    func goToCartDetail(id: UUID)
}
```

---

### DIP: Dependency Inversion Principle

```swift
final class Injector {
    private let userRepository: UserRepository
    private let userLoginUseCase: UserLoginUseCase

    init() {
        userRepository = DefaultUserRepository(/*...*/)
        userLoginUseCase = UserLoginUseCase(repository: userRepository)
    }
}
```

---

## Dependency Injection & The Injector

A single **Injector** composes all dependencies for the app at startup.
No feature or ViewModel creates its own dependencies—everything is injected.

**How it works:**

* The `Injector` builds navigators, repositories, use cases, and UI modules.
* Each module receives its dependencies via initializer injection.
* Swap or mock any dependency by updating the Injector.

**Example:**

```swift
final class Injector {
    static let shared = Injector()

    let homeUIDI: HomeUIDI

    private init() {
        let appNavigator = Navigation()
        let homeNavigator = HomeNavigator(navigator: appNavigator)
        homeUIDI = HomeUIDI(navigation: homeNavigator)
        // ...set up other features
    }
}
```

This keeps dependencies explicit, feature code decoupled, and testing simple.

---

## Navigation Registry & Tab Management

* **Destinations are registered at app launch:** Each route (per feature) is mapped to a view factory.
* **Navigators push new destinations by protocol:** Features never manage navigation stacks directly.
* **TabView hosts a separate navigation stack per tab.** Switching tabs resets navigation as needed.

```swift
// Registering all navigation destinations at launch
extension Navigation {
    static func registerAllDestinations(using injector: Injector) {
        let appNavigator = injector.appNavigator

        appNavigator.register { (destination: HomeDestination) in
            injector.homeUIDI.makeView(for: destination)
        }
        appNavigator.register { (destination: WishlistDestination) in
            injector.wishlistUIDI.makeView(for: destination)
        }
        appNavigator.register { (destination: CartDestination) in
            injector.cartUIDI.makeView(for: destination)
        }
    }
}
```

**Features receive only navigator protocols**:

```swift
final class WishlistNavigator: WishlistNavigation {
    private unowned let navigator: Navigation

    func openWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }

    func goToCartDetail(id: UUID) {
        navigator.push(CartDestination.detail(id: id), tab: .cart)
    }
}
```

---

## Root Layer & Authentication Flow

* **RootScreenViewModel** observes user authentication status and switches between login and main UI tabs automatically.
* **RootUIDI** composes the login flow, tab view, and injects all feature UI modules.

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

    init(
        observeUserLoggedIn: ObserveUserIsLoggedInUseCaseProtocol,
        initial: RootDestination = .main
    ) {
        self.observeUserLoggedIn = observeUserLoggedIn
        self.path = initial

        cancellable = observeUserLoggedIn.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loggedIn in
                self?.path = loggedIn ? .main : .login
            }
    }
}
```

---

## Feature Module Example

Each feature contains:

* Domain (protocols, use cases)
* Data (implementations)
* DI (feature composition, UI injection)
* UI (SwiftUI views and ViewModels)

**Feature navigation is protocol-driven and injected**:

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

    func goToWishlistDetail(id: UUID) {
        navigator.push(WishlistDestination.detail(id: id), tab: .wishlist)
    }
}
```

**ViewModels and Views are injected with only what they need:**

```swift
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        // Render home UI and interact with viewModel
    }
}
```

---

## Adding a New Feature

1. Create your module under `Component/FeatureName/`
   (e.g., `Component/Profile/Domain/`, `Component/Profile/Data/`, etc.)
2. Define your domain protocols and use cases.
3. Implement repository/data sources.
4. Create navigator protocols and destination enums.
5. Implement your navigator, register it in `Navigation+registerAllDestinations.swift`.
6. Create a `FeatureUIDI` entry point for composing the feature UI, injected via `Injector.swift` and `RootUIDI.swift`.

---

## Getting Started

* Open in **Xcode 15+** with **Swift 5.9+**.
* App boots from `Boot.swift`, registering destinations and building DI via `Injector.swift`.
* The root layer composes authentication flow and main tabbed navigation.
* All features are fully modular—follow the pattern to add more.

---

## Resources

* [Denis Brandi: Android Clean Architecture Example](https://github.com/DenisBronx/Real-Clean-Architecture-In-Android---Sample)
* [The Clean Architecture (Uncle Bob)](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Clean Swift (iOS Focused)](https://clean-swift.com/clean-swift-ios-architecture/)
* [Clean Architecture in iOS (Essential Developer)](https://www.essentialdeveloper.com/articles/clean-architecture-in-ios/)

---

## License

MIT. Fork, use, or adapt for any project. Attribution is required.
