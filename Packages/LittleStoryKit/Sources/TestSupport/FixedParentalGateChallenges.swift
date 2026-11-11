import Common

/// Always asks the same question, so tests and UI journeys can answer the parental gate.
public struct FixedParentalGateChallenges: ParentalGateChallenges {
    public let challenge: ParentalGateChallenge

    public init(challenge: ParentalGateChallenge = ParentalGateChallenge(first: 14, second: 7)) {
        self.challenge = challenge
    }

    public func next() -> ParentalGateChallenge { challenge }
}
