import SwiftUI

struct APODCardView: View {
    let card: APODCard
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onRetry: () -> Void
    let onShare: () -> Void

    @State private var animateIn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.date)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(card.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)

            if case .placeholder = card.state {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.8))
                    .overlay {
                        ProgressView()
                    }
                    .frame(height: 165)
            } else {
                imageSection
            }

            Text(card.explanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            actionRow

            if case let .failed(message) = card.state {
                HStack {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
        )
        .scaleEffect(animateIn ? 1 : 0.97)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.82)) {
                animateIn = true
            }
        }
    }

    private var imageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.93, green: 0.95, blue: 0.98))

            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 165)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: card.image != nil)
            } else if card.isImageLoading {
                ProgressView("Rendering image...")
                    .tint(.indigo)
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 165)
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                onToggleFavorite()
            } label: {
                Label(isFavorite ? "Saved" : "Save", systemImage: isFavorite ? "heart.fill" : "heart")
            }
            .buttonStyle(.bordered)
            .tint(isFavorite ? .pink : .indigo)
            .contentTransition(.symbolEffect(.replace))
            .animation(.spring(response: 0.35, dampingFraction: 0.84), value: isFavorite)

            Spacer()

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .font(.caption)
    }
}
