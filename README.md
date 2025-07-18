# Clean Architecture Example for iOS

Welcome! This project demonstrates a pragmatic, production-ready approach to [Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) in Swift, using modern SwiftUI and strict concurrency. It’s designed to teach you *how* to implement Clean Architecture in scalable, modular iOS apps — and *why* you should.

---

## Why Clean Architecture?

Clean Architecture is all about **separation of concerns**, **independence**, and **testability**.

* **Separation of concerns:** Features, business logic, data, and UI are all decoupled.
* **Independence:** You can swap frameworks, change your data source, or redesign the UI — with minimal code changes elsewhere.
* **Testability:** Business logic and core rules live in pure Swift, not frameworks. That makes them easy to unit test.
* **Scalability:** Features can grow independently, allowing larger teams to work without stepping on each other.
* **Resilience to change:** You can adopt new Apple frameworks, architectures, or UI approaches without rewriting your app’s core.

In enterprise and long-lived apps, these benefits make a *huge* difference.

---

## Project Structure

This project uses these main layers, which map directly to Clean Architecture concepts:

```
├── Application/          # Entry point, bootstrapping, dependency graph
├── Component/            # Business logic, data, domain (e.g. User)
├── Navigation/           # Navigation abstraction, tab & flow handling
├── Presentation/         # SwiftUI screens, ViewModels, UI Dependency Injection
```

### Layer Overview

| Layer            | Responsibility                            | Example Files                                  |
| ---------------- | ----------------------------------------- | ---------------------------------------------- |
| **Application**  | App launch, dependency injection, graph   | `Boot.swift`, `Injector.swift`                 |
| **Component**    | Feature modules: data, domain, DI         | `Component/User/Data`, `Component/User/Domain` |
| **Navigation**   | Flow and screen routing, navigators       | `AppNavigator.swift`, `HomeNavigator.swift`    |
| **Presentation** | SwiftUI views, ViewModels, UI composition | `Presentation/HomeUI/Presentation/*`           |

---

## How Clean Architecture Maps to Code

### 1. **Domain Layer** (`Component/User/Domain`)

* *Pure business rules.*
* Defines entities (like `User`), and repository contracts (`UserRepository`).
* UseCases wrap specific business logic (`UserLoginUseCase`, etc).
* *No reference to Apple frameworks or UI!*

### 2. **Data Layer** (`Component/User/Data`)

* Concrete implementations of repositories.
* Handles data sources, persistence, API calls.
* Example: `DefaultUserRepository` uses a `UserSession` and an `AuthClient`.

### 3. **Dependency Injection** (`Component/User/DI`)

* Assembles the feature’s dependencies, exposes ready-to-use UseCases.
* Isolated per feature, makes features portable and testable.

### 4. **Presentation Layer** (`Presentation/*UI`)

* Pure SwiftUI Views, each screen or flow in its own folder.
* ViewModels are injected with UseCases, never know about data or navigation.
* UI DI structs build ViewModels and screens (e.g. `HomeUIDI`).

### 5. **Navigation Abstraction** (`Navigation/`)

* Features never know about tab bar, navigation stacks, or how routing works.
* `Navigator` classes handle screen transitions, using an `AppNavigator` orchestrator.
* Makes it easy to evolve navigation, add new flows, or run feature modules in isolation.

### 6. **Application Bootstrap** (`Application/`)

* `Injector.swift` wires up the full dependency graph.
* `Boot.swift` is the app’s entry point, assembling the whole app.

---

## File Walkthrough

**Example:** Let’s look at the User feature.

* `Component/User/Domain/Repository/UserRepository.swift` — Defines *what* the repository must do (contract).
* `Component/User/Data/DefaultUserRepository.swift` — Implements the repository using data sources.
* `Component/User/Domain/UseCases/UserLoginUseCase.swift` — Business logic, only uses repository protocol.
* `Component/User/DI/UserDI.swift` — Wires together the feature dependencies.
* `Presentation/LoginUI/DI/LoginUIDI.swift` — Creates ViewModels and screens, injecting UseCases.

Navigation for each feature is handled by `*Navigator.swift` classes. The main navigator is `AppNavigator.swift`, which enables deep linking, tab switching, and navigation stack handling — all decoupled from UI and features.

---

## Why is This Important for Enterprise Apps?

* **You can onboard new team members faster.**
* **You can test business logic without running the UI or needing mocks of UIKit/SwiftUI.**
* **You can evolve, refactor, or migrate features and data sources independently.**
* **You can scale the codebase as features and teams grow.**

---

## How to Explore This Example

* Start with `Application/Boot.swift` to see how the app boots.
* Follow how `Injector.swift` wires dependencies.
* Look at any feature folder under `Component/` for its data/domain separation.
* See how each `*UIDI.swift` handles UI dependency injection, keeping your Views clean and easy to preview.
* Notice that ViewModels *never* reference navigation, and that business logic lives in UseCases, not in your Views.

---

## Want to Try It Out?

Open in Xcode (Swift 5.9+), build, and run. You’ll see a tab-based app with “Home”, “Favorites”, and “Cart” — each feature independently navigable and easily extensible.

Try swapping out repositories, refactoring features, or replacing navigation approaches. Clean Architecture makes this easy.

---

## Clean Architecture Resources

* [The Clean Architecture (Uncle Bob)](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Clean Swift (iOS Focused)](https://clean-swift.com/clean-swift-ios-architecture/)
* [Why Clean Architecture? (Thoughts on scaling iOS codebases)](https://www.essentialdeveloper.com/articles/clean-architecture-in-ios/)

---

**Questions, feedback, or want to contribute? PRs and issues welcome!**

---

Let me know if you want to see specific workflow examples, diagrams, or a deeper dive into one feature’s implementation.

**Feel free to explore the code and see how each layer communicates.
Fork this for your next Swift project (but please check the license and give me a shout out!), or use it as a study reference.**

Modelled after https://github.com/DenisBronx/Real-Clean-Architecture-In-Android---Sample by @DenisBronx
