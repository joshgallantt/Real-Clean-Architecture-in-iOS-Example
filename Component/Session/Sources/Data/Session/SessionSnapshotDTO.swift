import Foundation

struct SessionSnapshotDTO: Codable {
    struct UserDTO: Codable {
        let id: Int
        let email: String
        let firstName: String
        let lastName: String
    }

    let user: UserDTO
    let tokenValue: String
    let expiresAt: Date
}
