# Clean Architecture Example in iOS

This repository demonstrates Clean Architecture in a modern iOS application, written in Swift and using SwiftUI.
It showcases strict separation of concerns, dependency injection, and navigation across a multi-tab interface.


## <br><br> 🏗️ Layer Overview & Data Flow

The architecture is structured into clear layers:

```
DataSource
   ↓
Repository
   ↓
Use Case
   ↓
ViewModel
   ↓
View
```

### <br> 1. **DataSource**

* **Role:** Provides raw data. Typically from API clients, persistence, or session state.
* **Files:**

  * `AuthClient.swift`, `UserSession.swift`, `AuthToken.swift`

#### Example

* `AuthClient` is an abstraction for network calls.
* `UserSession` is an observable session manager for the logged-in user and token.

### <br> 2. **Repository**

* **Role:** Acts as a bridge, adapting raw DataSources for use by the domain layer.
* **Files:**

  * `RealUserRepository.swift`
  * `UserRepository.swift` (protocol)

#### Example

* `RealUserRepository` takes a `UserSession` and `AuthClient`, exposes a clean API (`login`, `logout`, `isLoggedIn`) for the rest of the app.

### <br> 3. **Use Case**

* **Role:** Encapsulates business logic. Use cases are simple, focused actions (e.g., Login, Check Session).
* **Files:**

  * `UserLoginUseCase.swift`
  * `UserIsLoggedInUseCase.swift`
  * `ObserveUserIsLoggedInUseCase.swift`

#### Example

* `UserLoginUseCase` calls the repository to perform login and returns a success flag.

### <br> 4. **ViewModel**

* **Role:** Orchestrates UI state and side effects.
* **Files:**

  * `BootViewModel.swift`
  * `HomeScreenViewModel.swift`
  * `FavoritesScreenViewModel.swift`
  * `CartScreenViewModel.swift` (as "Watchlist" in your project)

#### Example

* `HomeScreenViewModel` provides functions to handle UI events, and triggers navigation via injected coordinators.

### 5. **View**

* **Role:** SwiftUI view code. Composes screen UI and binds to view models.
* **Files:**

  * All `*ScreenView.swift`

#### Example

* `LoginScreenView` binds form fields and triggers login via its use case.

## <br><br> 🔗 **Data Flow in Action**

### <br> Example: Logging In

1. **User enters credentials** on `LoginScreenView`.
2. The **View** triggers `UserLoginUseCase` through a button.
3. The **Use Case** calls `UserRepository.login`.
4. The **Repository** uses `AuthClient` to verify credentials, and updates `UserSession`.
5. UI observes session state and transitions as needed.

## <br><br> 🧩 **Dependency Injection**

### <br> How Injection Works

* The **Injector** singleton (`Injector.swift`) wires up all dependencies at app start.
* Each feature has a dedicated DI struct (e.g., `HomeUIDI`, `BootUIDI`) for assembling view models and views.
* Dependencies are injected **top-down**, e.g.,

  * UseCases get Repositories
  * ViewModels get UseCases
  * Views get ViewModels

#### Example (from `Injector.swift`):

```swift
userRepository = RealUserRepository(session: userSession, authClient: FakeAuthClient())
userLogin = UserLoginUseCase(userRepository: userRepository)
loginUIDI = LoginUIDI(userLogin: userLogin)
```

This ensures **no layer ever knows about a lower layer’s concrete types**, only their contracts.

## <br><br> 🧭 **Navigation**

### <br> How Navigation Works

Navigation is decoupled using navigator protocols and destination enums.

#### Core Principles:

* Each feature has its own **Navigator protocol** (e.g., `HomeNavigation`), implemented by a concrete navigator (`HomeNavigator`).
* **AppNavigator** owns and manages navigation state for all tabs. It registers and resolves navigation destinations using factory closures.
* **ViewModels** never perform navigation directly. They hold a reference to their navigator protocol.
* **Tab and stack navigation** is handled using `NavigationStack` and `TabView`, with each feature’s navigation path stored separately.

#### Example Flow

1. ViewModel calls its navigation protocol, e.g., `openHomeDetail(id:)`.
2. Concrete navigator calls `AppNavigator.push(HomeDestination.detail(id: ...))`.
3. `AppNavigator` updates the relevant `NavigationPath`.
4. SwiftUI’s `navigationDestination` resolves the destination using the registered factory.

## <br> 📁 **File Structure**

<details>
<summary>Click to expand</summary>

```
./CleanArchitecture
    /Navigation
        AppNavigator.swift
        FavoritesNavigator.swift
        WatchlistNavigator.swift
        HomeNavigator.swift
        BootViewModel.swift
    /Component/User/Data/DataSources
        DTO/AuthToken.swift
        UserSession.swift
        AuthClient.swift
    /Component/User/Data
        RealUserRepository.swift
    /Component/User/Domain/Repository
        UserRepository.swift
    /Component/User/Domain/Model
        User.swift
    /Component/User/Domain/UseCases
        UserLoginUseCase.swift
        UserIsLoggedInUseCase.swift
        ObserveUserIsLoggedInUseCase.swift
    /Application
        Boot.swift
        Injector.swift
    /Presentation/...
        (Feature folders: BootUI, HomeUI, FavoritesUI, WatchlistUI, MainUI, LoginUI)
        Each with DI, Navigation, Presentation folders/files
```

</details>

## <br><br> 📝 **Summary**

This project is a practical Clean Architecture implementation for iOS:

* **Strict boundaries** between layers
* **Composed navigation** for multi-feature apps
* **Dependency injection** ensures testability and loose coupling

If you want to add new features, follow the pattern:
**DataSource → Repository → UseCase → ViewModel → View**,
inject everything from the top, and keep navigation decoupled!

---

**Feel free to explore the code and see how each layer communicates.
Fork this for your next Swift project (but please check the license and give me a shout out!), or use it as a study reference.**

Modelled after https://github.com/DenisBronx/Real-Clean-Architecture-In-Android---Sample by @DenisBronx
