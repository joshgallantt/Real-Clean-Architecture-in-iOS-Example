import Foundation

public enum CreateAccountError: Error {
    case firstNameIsEmpty
    case emailIsEmpty
    case passwordIsEmpty
    case emailAlreadyInUse
    case unknown
}
