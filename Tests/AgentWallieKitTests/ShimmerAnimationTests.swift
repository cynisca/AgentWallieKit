import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class ShimmerAnimationTests: XCTestCase {

    // MARK: - Helper

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Shimmer Type Decoding

    func testShimmerAnimationType_decodesCorrectly() throws {
        let json = """
        { "type": "shimmer" }
        """
        let data = json.data(using: .utf8)!
        let anim = try JSONDecoder().decode(ComponentAnimation.self, from: data)
        XCTAssertEqual(anim.type, "shimmer")
        XCTAssertNil(anim.durationMs)
        XCTAssertNil(anim.delayMs)
    }

    func testShimmerAnimationType_withDuration() throws {
        let json = """
        { "type": "shimmer", "duration_ms": 3000 }
        """
        let data = json.data(using: .utf8)!
        let anim = try JSONDecoder().decode(ComponentAnimation.self, from: data)
        XCTAssertEqual(anim.type, "shimmer")
        XCTAssertEqual(anim.durationMs, 3000)
    }

    func testShimmerAnimationType_withDurationAndDelay() throws {
        let json = """
        { "type": "shimmer", "duration_ms": 3000, "delay_ms": 500 }
        """
        let data = json.data(using: .utf8)!
        let anim = try JSONDecoder().decode(ComponentAnimation.self, from: data)
        XCTAssertEqual(anim.type, "shimmer")
        XCTAssertEqual(anim.durationMs, 3000)
        XCTAssertEqual(anim.delayMs, 500)
    }

    // MARK: - Shimmer Recognized (Not Unknown)

    func testShimmerAnimationType_isRecognized() {
        // After the fix, AnimationTypeValue should include shimmer
        XCTAssertEqual(AnimationTypeValue.shimmer, "shimmer")
    }

    func testShimmerAnimationModifier_doesNotCrash() {
        let anim = ComponentAnimation(type: "shimmer", durationMs: 3000)
        let modifier = AnimationModifier(animation: anim)
        XCTAssertNotNil(modifier)
    }

    // MARK: - Round-Trip

    func testShimmerAnimation_roundTripEncodeDecode() throws {
        let anim = ComponentAnimation(type: "shimmer", durationMs: 3000, delayMs: 200)
        let decoded = try roundTrip(anim)
        XCTAssertEqual(decoded.type, "shimmer")
        XCTAssertEqual(decoded.durationMs, 3000)
        XCTAssertEqual(decoded.delayMs, 200)
    }

    // MARK: - On Component

    func testShimmerAnimationOnCTAButton() throws {
        let json = """
        {
            "type": "cta_button",
            "id": "cta_shimmer",
            "props": { "text": "Subscribe Now", "action": "purchase" },
            "animation": { "type": "shimmer", "duration_ms": 3000 }
        }
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)
        if case .ctaButton(let d) = component {
            XCTAssertNotNil(d.animation)
            XCTAssertEqual(d.animation?.type, "shimmer")
            XCTAssertEqual(d.animation?.durationMs, 3000)
        } else {
            XCTFail("Expected cta_button component")
        }
    }
}
