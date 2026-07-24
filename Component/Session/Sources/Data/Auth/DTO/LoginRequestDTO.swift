struct LoginRequestDTO: Encodable {
    let username: String
    let password: String
    let expiresInMins: Int
}
