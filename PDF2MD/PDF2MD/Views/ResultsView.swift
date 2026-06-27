import SwiftUI

/// Shows the per-file outcome of the most recent conversion run.
struct ResultsView: View {
    let outcomes: [ConversionOutcome]
    let onReveal: (URL) -> Void
    let onOpenFolder: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Results")
                        .font(.headline)
                    Spacer()
                    Button("Open Output Folder", action: onOpenFolder)
                        .controlSize(.small)
                }

                List(outcomes) { outcome in
                    row(for: outcome)
                }
                .listStyle(.inset)
                .frame(minHeight: 140)
            }
            .padding(6)
        }
    }

    @ViewBuilder
    private func row(for outcome: ConversionOutcome) -> some View {
        HStack(alignment: .top, spacing: 10) {
            switch outcome.status {
            case .success(let url):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 1) {
                    Text(outcome.sourceName)
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reveal") { onReveal(url) }
                    .controlSize(.small)
            case .failure(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text(outcome.sourceName)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }
}
