import XCTest
@testable import AgentWallieKit

@available(iOS 16.0, *)
final class AnimationTests: XCTestCase {

    // MARK: - Animation Types Recognized

    func testFadeInTypeRecognized() {
        let anim = ComponentAnimation(type: "fade_in")
        XCTAssertEqual(anim.type, "fade_in")
    }

    func testSlideUpTypeRecognized() {
        let anim = ComponentAnimation(type: "slide_up")
        XCTAssertEqual(anim.type, "slide_up")
    }

    func testSlideInLeftTypeRecognized() {
        let anim = ComponentAnimation(type: "slide_in_left")
        XCTAssertEqual(anim.type, "slide_in_left")
    }

    func testScaleUpTypeRecognized() {
        let anim = ComponentAnimation(type: "scale_up")
        XCTAssertEqual(anim.type, "scale_up")
    }

    func testBounceTypeRecognized() {
        let anim = ComponentAnimation(type: "bounce")
        XCTAssertEqual(anim.type, "bounce")
    }

    func testPulseTypeRecognized() {
        let anim = ComponentAnimation(type: "pulse")
        XCTAssertEqual(anim.type, "pulse")
    }

    func testShakeTypeRecognized() {
        let anim = ComponentAnimation(type: "shake")
        XCTAssertEqual(anim.type, "shake")
    }

    // MARK: - Default Duration / Delay

    func testDefaultDurationIsNil() {
        let anim = ComponentAnimation(type: "fade_in")
        XCTAssertNil(anim.durationMs)
    }

    func testDefaultDelayIsNil() {
        let anim = ComponentAnimation(type: "fade_in")
        XCTAssertNil(anim.delayMs)
    }

    func testAnimationModifierDefaultDuration() {
        XCTAssertEqual(AnimationModifier.defaultDurationSeconds, 0.3, accuracy: 0.001)
    }

    func testAnimationModifierDefaultDelay() {
        XCTAssertEqual(AnimationModifier.defaultDelaySeconds, 0.0, accuracy: 0.001)
    }

    // MARK: - Custom Duration / Delay

    func testCustomDuration() {
        let anim = ComponentAnimation(type: "fade_in", durationMs: 500)
        XCTAssertEqual(anim.durationMs, 500)
    }

    func testCustomDelay() {
        let anim = ComponentAnimation(type: "slide_up", delayMs: 200)
        XCTAssertEqual(anim.delayMs, 200)
    }

    func testCustomDurationAndDelay() {
        let anim = ComponentAnimation(type: "scale_up", durationMs: 1000, delayMs: 300)
        XCTAssertEqual(anim.durationMs, 1000)
        XCTAssertEqual(anim.delayMs, 300)
    }

    // MARK: - Nil Animation

    func testNilAnimationModifierDoesNotCrash() {
        let modifier = AnimationModifier(animation: nil)
        XCTAssertNotNil(modifier)
    }

    // MARK: - Unknown Animation Type

    func testUnknownAnimationTypeHandledGracefully() {
        let anim = ComponentAnimation(type: "unknown_type")
        XCTAssertEqual(anim.type, "unknown_type")
        // AnimationModifier with unknown type falls through to default (no animation)
        let modifier = AnimationModifier(animation: anim)
        XCTAssertNotNil(modifier)
    }

    // MARK: - Shimmer Animation

    func testShimmerTypeRecognized() {
        let anim = ComponentAnimation(type: "shimmer")
        XCTAssertEqual(anim.type, "shimmer")
        let modifier = AnimationModifier(animation: anim)
        XCTAssertNotNil(modifier)
    }

    // MARK: - Animation Type Constants

    func testAnimationTypeConstants() {
        XCTAssertEqual(AnimationTypeValue.fadeIn, "fade_in")
        XCTAssertEqual(AnimationTypeValue.slideUp, "slide_up")
        XCTAssertEqual(AnimationTypeValue.slideInLeft, "slide_in_left")
        XCTAssertEqual(AnimationTypeValue.scaleUp, "scale_up")
        XCTAssertEqual(AnimationTypeValue.bounce, "bounce")
        XCTAssertEqual(AnimationTypeValue.pulse, "pulse")
        XCTAssertEqual(AnimationTypeValue.shake, "shake")
        XCTAssertEqual(AnimationTypeValue.shimmer, "shimmer")
    }

    // MARK: - JSON Encoding/Decoding

    func testAnimationDecodingFromJSON() throws {
        let json = """
        {"type": "fade_in", "duration_ms": 400, "delay_ms": 100}
        """
        let data = json.data(using: .utf8)!
        let anim = try JSONDecoder().decode(ComponentAnimation.self, from: data)
        XCTAssertEqual(anim.type, "fade_in")
        XCTAssertEqual(anim.durationMs, 400)
        XCTAssertEqual(anim.delayMs, 100)
    }

    func testAnimationDecodingMinimalJSON() throws {
        let json = """
        {"type": "bounce"}
        """
        let data = json.data(using: .utf8)!
        let anim = try JSONDecoder().decode(ComponentAnimation.self, from: data)
        XCTAssertEqual(anim.type, "bounce")
        XCTAssertNil(anim.durationMs)
        XCTAssertNil(anim.delayMs)
    }
}
