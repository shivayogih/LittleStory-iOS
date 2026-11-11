import DesignSystem
import SwiftUI

/// A story cover: the palette's gradient, a moon, a hill and the story's motif, drawn in shapes so it
/// scales from a list thumbnail to the detail header. Unknown ids use the friendship gradient and a
/// child figure (Android `StoryArt` placeholder rule).
public struct StoryArt: View {
    private let paletteID: String
    private let motifID: String

    public init(paletteID: String, motifID: String) {
        self.paletteID = paletteID
        self.motifID = motifID
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let unit = min(size.width, size.height)
            ZStack {
                LSColor.StoryArt.gradient(paletteID: paletteID).linear
                Sparkles(unit: unit)
                Moon(unit: unit)
                    .position(x: size.width * Geometry.moonX, y: size.height * Geometry.moonY)
                Ellipse()
                    .fill(LSColor.night.opacity(LSDimens.storyHillOpacity))
                    .frame(width: size.width * Geometry.hillWidth, height: size.height * Geometry.hillHeight)
                    .position(x: size.width / 2, y: size.height * Geometry.hillY)
                StoryMotif(motifID: motifID, unit: unit)
                    .position(x: size.width * Geometry.motifX, y: size.height * Geometry.motifY)
            }
        }
        .accessibilityHidden(true)
    }

    private enum Geometry {
        static let moonX = 0.72
        static let moonY = 0.26
        static let hillWidth = 1.6
        static let hillHeight = 0.5
        static let hillY = 1.02
        static let motifX = 0.5
        static let motifY = 0.74
    }
}

/// Crescent moon: a pale disc with a shifted disc of the motif tint over it.
struct Moon: View {
    let unit: CGFloat
    private static let sizeRatio = 0.3
    private static let biteOffset = 0.32
    private static let biteOpacity = 0.85

    var body: some View {
        let diameter = unit * Self.sizeRatio
        ZStack {
            Circle().fill(LSColor.moon)
            Circle()
                .fill(LSColor.warmAccent.opacity(Self.biteOpacity))
                .offset(x: -diameter * Self.biteOffset, y: -diameter * Self.biteOffset / 2)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(.circle)
    }
}

/// Two small four-point sparkles in the sky.
struct Sparkles: View {
    let unit: CGFloat
    private static let size = 0.07
    private static let dot = 0.025
    private static let sparkleX = 0.18
    private static let sparkleY = 0.2
    private static let dotX = 0.28
    private static let dotY = 0.38

    var body: some View {
        GeometryReader { proxy in
            Sparkle()
                .fill(LSColor.onPrimary)
                .frame(width: unit * Self.size, height: unit * Self.size)
                .position(x: proxy.size.width * Self.sparkleX, y: proxy.size.height * Self.sparkleY)
            Circle()
                .fill(LSColor.onPrimary)
                .frame(width: unit * Self.dot, height: unit * Self.dot)
                .position(x: proxy.size.width * Self.dotX, y: proxy.size.height * Self.dotY)
        }
    }
}

/// A four-point star.
public struct Sparkle: Shape {
    private static let waist = 0.18

    public init() {}

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let waistX = rect.width * Self.waist
        let waistY = rect.height * Self.waist
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: center.x + waistX, y: center.y - waistY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: center.x + waistX, y: center.y + waistY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: center.x - waistX, y: center.y + waistY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: center.x - waistX, y: center.y - waistY))
        path.closeSubpath()
        return path
    }
}

/// The figure on a cover: an elephant for `elephant`, otherwise a child (holding a bat for `cricket`).
struct StoryMotif: View {
    let motifID: String
    let unit: CGFloat

    var body: some View {
        if motifID == Motif.elephant {
            Elephant(unit: unit)
        } else {
            ChildFigure(unit: unit, holdsBat: motifID == Motif.cricket, top: shirt)
        }
    }

    private var shirt: Color {
        switch motifID {
        case Motif.forest: LSColor.Illustration.heroHill
        case Motif.space: LSColor.Illustration.childTop
        case Motif.festival: LSColor.Illustration.terracotta
        default: LSColor.Illustration.shirtGold
        }
    }

    private enum Motif {
        static let elephant = "elephant"
        static let cricket = "cricket"
        static let forest = "forest"
        static let space = "space"
        static let festival = "festival"
    }
}

/// A child seen from behind the hill: hair, face and a rounded top.
public struct ChildFigure: View {
    private let unit: CGFloat
    private let holdsBat: Bool
    private let top: Color
    private static let headWidth = 0.2
    private static let headHeight = 0.26
    private static let bodyWidth = 0.3
    private static let bodyHeight = 0.2
    private static let hairHeight = 0.12
    private static let batWidth = 0.025
    private static let batHeight = 0.36
    private static let batTilt = -14.0
    private static let batOffset = 0.2

    public init(unit: CGFloat, holdsBat: Bool = false, top: Color = LSColor.Illustration.shirtGold) {
        self.unit = unit
        self.holdsBat = holdsBat
        self.top = top
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            if holdsBat {
                Capsule()
                    .fill(LSColor.Illustration.cricketBat)
                    .frame(width: unit * Self.batWidth, height: unit * Self.batHeight)
                    .rotationEffect(.degrees(Self.batTilt))
                    .offset(x: unit * Self.batOffset)
            }
            VStack(spacing: LSSpacing.none) {
                ZStack(alignment: .top) {
                    Capsule().fill(LSColor.Illustration.skin)
                    UnevenRoundedRectangle(topLeadingRadius: unit, topTrailingRadius: unit)
                        .fill(LSColor.Illustration.hair)
                        .frame(height: unit * Self.hairHeight)
                }
                .frame(width: unit * Self.headWidth, height: unit * Self.headHeight)
                .clipShape(.capsule)
                UnevenRoundedRectangle(topLeadingRadius: unit, topTrailingRadius: unit)
                    .fill(top)
                    .frame(width: unit * Self.bodyWidth, height: unit * Self.bodyHeight)
            }
        }
    }
}

/// A friendly elephant in profile: body, head, legs and trunk.
struct Elephant: View {
    let unit: CGFloat
    private static let bodyWidth = 0.42
    private static let bodyHeight = 0.26
    private static let headSize = 0.2
    private static let legWidth = 0.06
    private static let legHeight = 0.12
    private static let headOffsetX = 0.2
    private static let headOffsetY = -0.06
    private static let legSpread = 0.12
    private static let legOffsetY = 0.14

    var body: some View {
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                RoundedRectangle(cornerRadius: unit * Self.legWidth / 2)
                    .fill(LSColor.Illustration.elephantLeg)
                    .frame(width: unit * Self.legWidth, height: unit * Self.legHeight)
                    .offset(x: unit * Self.legSpread * side, y: unit * Self.legOffsetY)
            }
            Ellipse()
                .fill(LSColor.Illustration.elephant)
                .frame(width: unit * Self.bodyWidth, height: unit * Self.bodyHeight)
            Circle()
                .fill(LSColor.Illustration.elephantLight)
                .frame(width: unit * Self.headSize, height: unit * Self.headSize)
                .offset(x: unit * Self.headOffsetX, y: unit * Self.headOffsetY)
        }
    }
}
