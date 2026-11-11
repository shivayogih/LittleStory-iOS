@testable import DesignSystem
import SwiftUI
import Testing

struct LayoutClassTests {
    @Test("Width picks the class at the token breakpoints", arguments: [
        (CGFloat(375), LayoutClass.compact),
        (LayoutTokens.mediumMinWidth - 1, .compact),
        (LayoutTokens.mediumMinWidth, .medium),
        (LayoutTokens.expandedMinWidth - 1, .medium),
        (LayoutTokens.expandedMinWidth, .expanded),
        (1366, .expanded),
    ])
    func widths(width: CGFloat, expected: LayoutClass) {
        #expect(LayoutClass(width: width, sizeClass: .regular, dynamicTypeSize: .large) == expected)
    }

    @Test("A compact size class always means compact, even when wide")
    func compactSizeClass() {
        #expect(LayoutClass(width: 1200, sizeClass: .compact, dynamicTypeSize: .large) == .compact)
    }

    @Test("Accessibility text sizes step down one class")
    func accessibilitySizes() {
        #expect(LayoutClass(width: 1200, sizeClass: .regular, dynamicTypeSize: .accessibility5) == .medium)
        #expect(LayoutClass(width: 700, sizeClass: .regular, dynamicTypeSize: .accessibility1) == .compact)
    }

    @Test("Split view and reader spread follow the class")
    func behaviours() {
        #expect(!LayoutClass.compact.usesSplitView)
        #expect(LayoutClass.medium.usesSplitView)
        #expect(!LayoutClass.medium.showsReaderSpread)
        #expect(LayoutClass.expanded.showsReaderSpread)
    }
}
