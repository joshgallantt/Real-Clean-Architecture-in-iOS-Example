//
//  LoginUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

public protocol LoginUseCase: Sendable {
    func callAsFunction(email: String, password: String) async -> Result<Void, LoginError>
}

public struct DefaultLoginUseCase: LoginUseCase {
    let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func callAsFunction(email: String, password: String) async -> Result<Void, LoginError> {
        if email.isEmpty {
            return .failure(.emailIsEmpty)
        }
        if password.isEmpty {
            return .failure(.passwordIsEmpty)
        }
        return await sessionRepository.login(email: email, password: password)
    }
}
