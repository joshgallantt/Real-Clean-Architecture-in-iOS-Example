//
//  UserLoginUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

public protocol UserLoginUseCase {
    @MainActor
    func execute(username: String, password: String) async -> Result<Void, LoginError>
}

public struct DefaultUserLoginUseCase: UserLoginUseCase {
    let userRepository: UserRepository

    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    @MainActor
    public func execute(username: String, password: String) async -> Result<Void, LoginError> {
        if username.isEmpty {
            return .failure(.usernameIsEmpty)
        }
        if password.isEmpty {
            return .failure(.passwordIsEmpty)
        }
        return await userRepository.login(username: username, password: password)
    }
}
