# Clean Architecture Example for iOS

A pragmatic, production-ready [Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) example using SwiftUI, strict concurrency, and scalable patterns for iOS.

---

## Why Clean Architecture?

* **Separation of Concerns:** Business logic, data, and UI are decoupled.
* **Testability:** Pure Swift business logic, independent of Apple frameworks.
* **Scalability:** Features and teams grow independently.
* **Resilience:** Swap UI, frameworks, or data sources with minimal effort.

---

## Project Structure

```plaintext
├── Application/      # App entry point, bootstrapping, dependency graph
├── Component/        # Feature modules: data, domain, DI
├── Navigation/       # Navigation abstraction, navigators, flows
├── Presentation/     # SwiftUI views, ViewModels, UI composition/DI
```

| Layer        | Role                      | Example Files                           |
| ------------ | ------------------------- | --------------------------------------- |
| Application  | Launch, graph, DI         | Boot.swift, Injector.swift              |
| Component    | Data/domain per feature   | User/Data, User/Domain, etc             |
| Navigation   | Routing, navigators       | AppNavigator.swift, HomeNavigator.swift |
| Presentation | SwiftUI views, ViewModels | HomeUI/Presentation/*, LoginUI/*        |

---

## Layer Overview

* **Domain:** Entities, protocols, and use cases. No Apple frameworks.
* **Data:** Implements repositories and data sources.
* **DI:** Assembles feature dependencies.
* **Presentation:** SwiftUI Views and ViewModels, using DI.
* **Navigation:** All routing is abstracted—no UI logic in features.
* **Application:** Bootstraps and wires up everything.

---

## SOLID Principles in Practice

Clean Architecture is powered by [SOLID](https://en.wikipedia.org/wiki/SOLID), five principles for designing modular, maintainable code. Here's how each applies, with a complete example:

| Principle | How It's Applied                                                          |
| --------- | ------------------------------------------------------------------------- |
| SRP       | Each type/class/module has a single job (UseCase for business logic, etc) |
| OCP       | Can add new repository implementations or navigation flows freely         |
| LSP       | Any `UserRepository` can be swapped in for testing or production          |
| ISP       | Protocols focused only on what the feature needs                          |
| DIP       | High-level code (UseCases, ViewModels) depend on protocols, not concrete  |

```swift
// SRP — Single Responsibility: Each type does one job

protocol UserRepository { // ISP — Interface Segregation: Only user-related methods
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String) async throws -> User
    // No unrelated methods!
}

struct UserLoginUseCase { // SRP: Handles only user login use case
    let repository: UserRepository // DIP — Dependency Inversion: Depends on protocol

    func execute(email: String, password: String) async throws -> User {
        try await repository.login(email: email, password: password)
    }
}

// OCP — Open/Closed: Can extend with new implementations, no change needed here

struct DefaultUserRepository: UserRepository { // Concrete data layer
    func login(email: String, password: String) async throws -> User {
        // Actual login logic (e.g. API, local, etc)
        return User(email: email)
    }
    func register(email: String, password: String) async throws -> User {
        // Actual register logic
        return User(email: email)
    }
}

struct MockUserRepository: UserRepository { // LSP — Liskov Substitution: Safe to swap
    func login(email: String, password: String) async throws -> User {
        return User(email: email)
    }
    func register(email: String, password: String) async throws -> User {
        return User(email: email)
    }
}

// Usage — OCP: Swap repositories with no changes elsewhere
let useCase = UserLoginUseCase(repository: DefaultUserRepository())
// Or, for testing:
let mockUseCase = UserLoginUseCase(repository: MockUserRepository())
```

---

## Example: The "User" Feature

* `Component/User/Domain/Repository/UserRepository.swift`: Repository contract.
* `Component/User/Data/DefaultUserRepository.swift`: Concrete implementation.
* `Component/User/Domain/UseCases/UserLoginUseCase.swift`: Business logic.
* `Component/User/DI/UserDI.swift`: Dependency injection.
* `Presentation/LoginUI/DI/LoginUIDI.swift`: UI DI.

Navigation is handled via `*Navigator.swift` classes—completely decoupled from features and UI.

---

## Why This Structure?

* **Easy onboarding:** Clear, isolated modules.
* **Test without UI:** Core logic never depends on Apple frameworks.
* **Safe to refactor:** Swap implementations, add features, or migrate data sources independently.

---

## Getting Started

* Open in Xcode 15+ (Swift 5.9+).
* Explore from `Application/Boot.swift`.
* Trace dependency setup in `Injector.swift`.
* Follow any feature in `Component/` for full data/domain separation.
* Notice: ViewModels never reference navigation, and UseCases have no UI code.

---

## Resources

* [Denis Brandi: Android Clean Architecture Example](https://github.com/denisbrandi/clean-architecture-example)
* [The Clean Architecture (Uncle Bob)](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Clean Swift (iOS Focused)](https://clean-swift.com/clean-swift-ios-architecture/)
* [Clean Architecture in iOS (Essential Developer)](https://www.essentialdeveloper.com/articles/clean-architecture-in-ios/)

---

## License

Use, fork, or reference for your next project. Please check the license and give a shout out if helpful!
