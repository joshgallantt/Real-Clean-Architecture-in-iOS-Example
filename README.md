# Clean Architecture iOS Template

A robust, production-ready template for SwiftUI apps, architected around Clean Architecture, SOLID principles, and strict Swift 5.9+ concurrency. Each feature is isolated, navigation is registry-driven, and everything is testable by default.

---

## Contents

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
* **Authentication-first root:** The root layer observes authentication state and automatically switches between login and tabbed main UI.
* **100% SOLID:** Every layer is protocol-oriented for maximal testability and decoupling.
* **Strict concurrency:** Architected for Swift 5.9+ concurrency enforcement.

---

## Project Structure

```plaintext
├── Application/         # App entry, dependency graph (DI)
│   ├── Boot.swift
│   └── Injector.swift
├── Navigation/          # Tab/feature navigators, registry, protocols
│   ├── HomeNavigator.swift
│   ├── WishlistNavigator.swift
│   ├── CartNavigator.swift
│   └── _Navigation+registerAllDestinations.swift
├── Root/                # Auth observer, root screen, tab UI composition
│   ├── DI/
│   │   └── RootUIDI.swift
│   └── Presentation/
│       ├── RootScreen/
│       │   ├── RootDestination.swift
│       │   ├── RootScreenView.swift
│       │   └── RootScreenViewModel.swift
│       └── NavigationScreen/
│           ├── Navigation.swift
│           └── NavigationScreen.swift
├── Component/           # Feature modules: domain, data, DI, UI per module
│   ├── Home/
│   ├── Wishlist/
│   └── Cart/
```

| Layer       | Role                                 | Example Files                                  |
| ----------- | ------------------------------------ | ---------------------------------------------- |
| Application | Launch, DI graph                     | Boot.swift, Injector.swift                     |
| Navigation  | Navigators, registry, protocols      | HomeNavigator.swift, CartNavigator.swift, ...  |
| Root        | Auth state, login/tab switcher       | RootUIDI.swift, RootScreenView\.swift, ...     |
| Component   | Features (Home, Wishlist, Cart, ...) | Home/, Wishlist/, Cart/ (domain, data, UI, DI) |

---

## Architecture Breakdown

**Clean Architecture** separates business logic, data, UI, and navigation.

* **Domain:** Pure business logic and protocols. No frameworks.
* **Data:** Repository implementations, data sources (remote/local).
* **Presentation:** SwiftUI Views and ViewModels. No business or navigation logic.
* **Navigation:** Injected navigator protocols. Actual navigation is centralized.
* **Root/Application:** DI graph bootstrapping, navigation registry, root flow control.

**Why this matters:**

* Swap any implementation (UI, data, navigation) with zero effect on business logic.
* Pure Swift unit tests for all core flows.
* Feature devs onboard to a single module without full app context.

---

## SOLID in Practice (Swift snippets)

| Principle | How it’s applied in this codebase                    |
| --------- | ---------------------------------------------------- |
| SRP       | Each type/class/module has a single responsibility   |
| OCP       | Add new features/flows by addition, not modification |
| LSP       | Any protocol conformer can be swapped anywhere       |
| ISP       | Protocols are lean; only what consumers need         |
| DIP       | All wiring uses abstractions, never concrete types   |

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

### OCP: Open/Closed Principle

```swift
// Add new repository implementations without changing consumer code.
struct MockUserRepository: UserRepository {
    func login(email: String, password: String) async throws -> User { User(email: email) }
    func register(email: String, password: String) async throws -> User { User(email: email) }
}
```

### LSP: Liskov Substitution Principle

```swift
protocol CartNavigation {
    func openCartDetail(id: UUID)
}

final class CartNavigator: CartNavigation { /* ... */ }
final class TestCartNavigator: CartNavigation { /* ... */ }

// Swap any CartNavigation in DI; consumer is unaware.
```

### ISP: Interface Segregation Principle

```swift
// Protocol exposes only the actions needed for Wishlist.
protocol WishlistNavigation {
    func openWishlistDetail(id: UUID)
    func goToCartDetail(id: UUID)
}
```

### DIP: Dependency Inversion Principle

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

## Dependency Injection & The Injector

A singleton **Injector** composes all dependencies at startup.
No ViewModel or feature creates its own dependencies—everything is injected.

**How it works:**

* `Injector` builds navigators, repositories, use cases, and UI modules.
* Each module receives its dependencies via initializer injection.
* Swap or mock any dependency by updating the Injector.

```swift
final class Injector {
    static let shared = Injector()
    // ... component and navigator setup ...
    private init() { /* ... see code ... */ }
}
```

---

## Navigation Registry & Tab Management

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
    // ...
}
```

---

## Root Layer & Authentication Flow

* **RootScreenViewModel** observes user authentication status, switches between login and main UI tabs.
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

## Feature Module Example

Each feature contains:

* Domain (protocols, use cases)
* Data (implementations)
* DI (feature composition, UI injection)
* UI (SwiftUI views, ViewModels)

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
    // ...
}
```

**ViewModels and Views only get what they need:**

```swift
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    // ...
}
```

---

## Adding a New Feature

1. Create a module under `Component/FeatureName/`
2. Define your domain protocols and use cases.
3. Implement repositories/data sources.
4. Create navigator protocols and destination enums.
5. Implement your navigator, register it in `Navigation+registerAllDestinations.swift`.
6. Create a `FeatureUIDI` entry point for feature UI composition.
7. Inject via `Injector.swift` and wire into `RootUIDI.swift`.

---

## Getting Started

* Open in **Xcode 15+** with **Swift 5.9+**.
* App boots from `Boot.swift`, registering destinations and building the DI graph via `Injector.swift`.
* The root layer handles authentication flow and tabbed navigation.
* All features are modular—follow the same pattern to add more.

---

## Resources

* [Denis Brandi: Android Clean Architecture Example](https://github.com/DenisBronx/Real-Clean-Architecture-In-Android---Sample)
* [The Clean Architecture (Uncle Bob)](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Clean Swift (iOS Focused)](https://clean-swift.com/clean-swift-ios-architecture/)
* [Clean Architecture in iOS (Essential Developer)](https://www.essentialdeveloper.com/articles/clean-architecture-in-ios/)

---

## License

MIT. Fork, use, or adapt for any project. Attribution required.
