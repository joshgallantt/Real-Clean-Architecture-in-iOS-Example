import SwiftUI

public struct SettingsScreenView: View {
    @State private var viewModel: SettingsScreenViewModel

    public init(viewModel: @autoclosure @escaping () -> SettingsScreenViewModel) {
        self._viewModel = State(wrappedValue: viewModel())
    }

    public var body: some View {
        Form {
            ForEach(viewModel.sections) { section in
                Section(section.title) {
                    ForEach(section.rows) { row in
                        Toggle(
                            row.title,
                            isOn: Binding(
                                get: { row.isOn },
                                set: { viewModel.didToggle(row.id, to: $0) }
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            viewModel.onAppear()
        }
    }
}
