/// One grown-up check for the parental gate: a multiplication a young child is unlikely to solve,
/// asked before parent-only screens, links out and purchases (App Store guideline 1.3).
public struct ParentalGateChallenge: Sendable, Equatable {
    public let first: Int
    public let second: Int

    public init(first: Int, second: Int) {
        self.first = first
        self.second = second
    }

    public var answer: Int { first * second }

    /// True when `input` is the answer. Any Unicode decimal digits count, so Kannada digits (೦–೯)
    /// work too; spaces are ignored and anything else is a wrong answer.
    public func isAnswered(by input: String) -> Bool {
        let digits = input.filter { !$0.isWhitespace }.map(Self.decimalDigit)
        guard !digits.isEmpty, digits.count <= AppConfig.ParentalGate.maxAnswerDigits else { return false }
        var total = 0
        for digit in digits {
            guard let digit else { return false }
            total = total * Self.decimalBase + digit
        }
        return total == answer
    }

    private static let decimalBase = 10

    /// The value of a single decimal digit in any script, or nil (so "Ⅻ" or "½" are not digits).
    private static func decimalDigit(_ character: Character) -> Int? {
        guard character.unicodeScalars.count == 1,
              let scalar = character.unicodeScalars.first,
              scalar.properties.numericType == .decimal,
              let value = scalar.properties.numericValue
        else { return nil }
        return Int(value)
    }
}

/// Source of gate questions; the app uses `RandomParentalGateChallenges`, tests a fixed one.
public protocol ParentalGateChallenges: Sendable {
    func next() -> ParentalGateChallenge
}

public struct RandomParentalGateChallenges: ParentalGateChallenges {
    public init() {}

    public func next() -> ParentalGateChallenge {
        ParentalGateChallenge(
            first: Int.random(in: AppConfig.ParentalGate.firstFactorRange),
            second: Int.random(in: AppConfig.ParentalGate.secondFactorRange),
        )
    }
}
