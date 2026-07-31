import Foundation

/// Fowler, *PoEAA* (2002) — Data Transfer Object: the serialisation shape, kept out of the domain.
/// It maps at the boundary, so a wire format change stops here.
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
