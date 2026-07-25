import SnackbarUI

public struct SnackbarUIDI {
    public let presenter: SnackbarPresenter

    @MainActor
    public init() {
        self.presenter = SnackbarPresenter()
    }
}
