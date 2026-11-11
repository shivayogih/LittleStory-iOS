import Common
import Testing
import TestSupport

struct ParentalGateTests {
    private let challenge = ParentalGateChallenge(first: 14, second: 7)

    @Test("Correct answers pass, in Latin or Kannada digits, ignoring spaces", arguments: ["98", " 98 ", "೯೮", "9 8"])
    func accepts(input: String) {
        #expect(challenge.isAnswered(by: input))
    }

    @Test("Wrong, empty, non-digit and over-long answers fail", arguments: ["97", "", "   ", "98a", "Ⅻ", "½", "0000098"])
    func rejects(input: String) {
        #expect(!challenge.isAnswered(by: input))
    }

    @Test("Random questions stay within the configured factor ranges")
    func randomRanges() {
        let source = RandomParentalGateChallenges()
        for _ in 0 ..< 200 {
            let next = source.next()
            #expect(AppConfig.ParentalGate.firstFactorRange.contains(next.first))
            #expect(AppConfig.ParentalGate.secondFactorRange.contains(next.second))
        }
    }

    @Test("The fixed source used by UI journeys always asks 14 × 7")
    func fixedSource() {
        #expect(FixedParentalGateChallenges().next().answer == 98)
    }
}
