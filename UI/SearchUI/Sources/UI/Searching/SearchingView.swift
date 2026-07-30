import SwiftUI
import Product

public struct SearchingView: View {
    @ObservedObject var viewModel: SearchingViewModel
    let onSelectHistory: (SearchTerm) -> Void
    let onSelectSuggestion: (Product) -> Void

    public init(
        viewModel: SearchingViewModel,
        onSelectHistory: @escaping (SearchTerm) -> Void,
        onSelectSuggestion: @escaping (Product) -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectHistory = onSelectHistory
        self.onSelectSuggestion = onSelectSuggestion
    }

    public var body: some View {
        List {
            if viewModel.suggestions.isEmpty {
                Section("Recent Searches") {
                    ForEach(viewModel.history.terms, id: \.text) { term in
                        Button {
                            onSelectHistory(term)
                        } label: {
                            Label(term.text, systemImage: "clock")
                        }
                    }
                    if !viewModel.history.isEmpty {
                        Button("Clear History", role: .destructive) {
                            viewModel.clearHistory()
                        }
                    }
                }
            } else {
                Section("Suggestions") {
                    ForEach(viewModel.suggestions) { product in
                        Button {
                            onSelectSuggestion(product)
                        } label: {
                            Text(product.title)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .task {
            await viewModel.onAppear()
        }
    }
}
