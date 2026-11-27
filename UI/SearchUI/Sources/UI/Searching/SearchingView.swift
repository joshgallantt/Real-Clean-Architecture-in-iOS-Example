import SwiftUI
import Product
import Tracking
import TrackingUI

public struct SearchingView: View {
    @Environment(\.trackingContext) private var trackingContext

    let viewModel: SearchingViewModel
    let onSelectHistory: (SearchTerm, TrackingContext) -> Void
    let onSelectSuggestion: (Product) -> Void

    public init(
        viewModel: SearchingViewModel,
        onSelectHistory: @escaping (SearchTerm, TrackingContext) -> Void,
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
                    ForEach(Array(viewModel.history.terms.enumerated()), id: \.element.text) { index, term in
                        TrackedRow(
                            onTap: { context in
                                viewModel.didSelect(term, in: context)
                                onSelectHistory(term, context)
                            },
                            onSeen: { viewModel.didSee(term, in: $0) }
                        ) {
                            Label(term.text, systemImage: "clock")
                        }
                        .trackingPosition(index)
                    }
                    if !viewModel.history.isEmpty {
                        Button("Clear History", role: .destructive) {
                            viewModel.clearHistory(in: trackingContext)
                        }
                    }
                }
                .trackingList(SearchTrackingPlan.history)
            } else {
                Section("Suggestions") {
                    ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, product in
                        TrackedRow(
                            onTap: { context in
                                viewModel.didSelect(product, in: context)
                                onSelectSuggestion(product)
                            },
                            onSeen: { viewModel.didSee(product, in: $0) }
                        ) {
                            Text(product.title)
                        }
                        .trackingPosition(index)
                    }
                }
                .trackingList(SearchTrackingPlan.suggestions)
            }
        }
        .listStyle(.plain)
        .task {
            await viewModel.onAppear()
        }
    }
}
