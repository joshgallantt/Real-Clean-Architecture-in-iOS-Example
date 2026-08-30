extension Result {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
