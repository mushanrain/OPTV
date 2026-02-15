import SwiftUI

/// Provides a reusable liquid-glass styling modifier that mimics the translucent cards in modern macOS.
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var elevation: CGFloat
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(materialBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(highlightStroke)
            .shadow(
                color: Color.black.opacity(colorScheme == .light ? 0.12 : 0.18),
                radius: elevation,
                x: 0,
                y: elevation / 2
            )
    }

    @ViewBuilder
    private var materialBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .light ? 0.6 : 0.38),
                                Color.white.opacity(colorScheme == .light ? 0.15 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            )
    }

    private var highlightStroke: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .light ? 0.7 : 0.55),
                        Color.white.opacity(colorScheme == .light ? 0.2 : 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.9
            )
            .blendMode(.overlay)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, elevation: CGFloat = 16) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, elevation: elevation))
    }

    @ViewBuilder
    func hideScrollIndicatorsIfAvailable() -> some View {
        if #available(macOS 13.0, *) {
            scrollIndicators(.hidden)
        } else {
            self
        }
    }
}

/// Capsule-based pill used for metadata chips such as “Pinned”.
struct LiquidChip: View {
    let text: String
    var tint: LinearGradient

    init(text: String, colors: [Color]) {
        self.text = text
        self.tint = LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(tint)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            .blendMode(.overlay)
                    )
            )
            .foregroundColor(.white.opacity(0.92))
    }
}

/// Shared icon view for clipboard items, matching the liquid glass look with SF Symbols.
struct LiquidSymbolIcon: View {
    let symbolName: String
    let gradient: [Color]
    let size: CGFloat

    init(symbolName: String, gradient: [Color], size: CGFloat = 34) {
        self.symbolName = symbolName
        self.gradient = gradient
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.9)
                        .blendMode(.overlay)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)

            Image(systemName: symbolName)
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundColor(.white.opacity(0.94))
        }
        .frame(width: size, height: size)
    }
}
