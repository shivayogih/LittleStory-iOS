import DesignSystem
import SwiftUI

/// Onboarding night sky: crescent moon with a soft glow, clouds, sparkles and a child reading.
public struct NightScene: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let unit = min(size.width, size.height)
            ZStack {
                LSColor.night
                Circle()
                    .fill(LSColor.moon)
                    .frame(width: unit * Geometry.moon, height: unit * Geometry.moon)
                    .overlay(
                        Circle()
                            .fill(LSColor.night)
                            .offset(x: -unit * Geometry.moonBite, y: -unit * Geometry.moonBite / 2),
                    )
                    .clipShape(.circle)
                    .shadow(color: LSColor.moon.opacity(Geometry.glowOpacity), radius: unit * Geometry.glow)
                    .position(x: size.width * Geometry.moonX, y: size.height * Geometry.moonY)
                ForEach(Geometry.clouds, id: \.self) { cloud in
                    Capsule()
                        .fill(LSColor.accent.opacity(Geometry.cloudOpacity))
                        .frame(width: unit * Geometry.cloudWidth, height: unit * Geometry.cloudHeight)
                        .position(x: size.width * cloud.x, y: size.height * cloud.y)
                }
                ForEach(Geometry.sparkles, id: \.self) { sparkle in
                    Sparkle()
                        .fill(LSColor.highlight)
                        .frame(width: LSDimens.sparkleSize, height: LSDimens.sparkleSize)
                        .position(x: size.width * sparkle.x, y: size.height * sparkle.y)
                }
                ReadingChild(unit: unit)
                    .position(x: size.width / 2, y: size.height * Geometry.childY)
            }
        }
        .accessibilityHidden(true)
    }

    private enum Geometry {
        static let moon = 0.42
        static let moonBite = 0.1
        static let moonX = 0.68
        static let moonY = 0.28
        static let glow = 0.08
        static let glowOpacity = 0.4
        static let cloudWidth = 0.26
        static let cloudHeight = 0.09
        static let cloudOpacity = 0.25
        static let clouds = [ScenePoint(x: 0.1, y: 0.3), ScenePoint(x: 0.9, y: 0.55)]
        static let sparkles = [ScenePoint(x: 0.17, y: 0.32), ScenePoint(x: 0.8, y: 0.26), ScenePoint(x: 0.26, y: 0.6)]
        static let childY = 0.82
    }
}

/// A position as fractions of the scene's width and height.
struct ScenePoint: Hashable {
    let x: Double
    let y: Double
}

/// A child behind an open book.
struct ReadingChild: View {
    let unit: CGFloat
    private static let pageWidth = 0.22
    private static let pageHeight = 0.18
    private static let pageTilt = 4.0
    private static let pageRadius = 0.03
    private static let childOffset = -0.12

    var body: some View {
        ZStack {
            ChildFigure(unit: unit, top: LSColor.Illustration.childTop)
                .offset(y: unit * Self.childOffset)
            HStack(spacing: LSSpacing.none) {
                page.rotationEffect(.degrees(Self.pageTilt))
                page.rotationEffect(.degrees(-Self.pageTilt))
            }
        }
    }

    private var page: some View {
        RoundedRectangle(cornerRadius: unit * Self.pageRadius)
            .fill(LSColor.moon)
            .frame(width: unit * Self.pageWidth, height: unit * Self.pageHeight)
    }
}
