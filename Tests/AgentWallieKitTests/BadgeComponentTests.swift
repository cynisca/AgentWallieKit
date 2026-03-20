import XCTest
@testable import AgentWallieKit

final class BadgeComponentTests: XCTestCase {

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Filled variant

    func testBadgeFilledRoundTrip() throws {
        let component = PaywallComponent.badge(BadgeComponentData(
            id: "b1",
            props: BadgeComponentData.BadgeProps(text: "BEST VALUE", variant: "filled")
        ))
        let decoded = try roundTrip(component)
        if case .badge(let d) = decoded {
            XCTAssertEqual(d.id, "b1")
            XCTAssertEqual(d.props.text, "BEST VALUE")
            XCTAssertEqual(d.props.variant, "filled")
            XCTAssertEqual(d.type, "badge")
        } else {
            XCTFail("Expected badge component")
        }
    }

    // MARK: - Outlined variant

    func testBadgeOutlinedRoundTrip() throws {
        let component = PaywallComponent.badge(BadgeComponentData(
            id: "b2",
            props: BadgeComponentData.BadgeProps(text: "SAVE 40%", variant: "outlined")
        ))
        let decoded = try roundTrip(component)
        if case .badge(let d) = decoded {
            XCTAssertEqual(d.id, "b2")
            XCTAssertEqual(d.props.text, "SAVE 40%")
            XCTAssertEqual(d.props.variant, "outlined")
        } else {
            XCTFail("Expected badge component")
        }
    }

    // MARK: - Soft variant

    func testBadgeSoftRoundTrip() throws {
        let component = PaywallComponent.badge(BadgeComponentData(
            id: "b3",
            props: BadgeComponentData.BadgeProps(text: "NEW", variant: "soft")
        ))
        let decoded = try roundTrip(component)
        if case .badge(let d) = decoded {
            XCTAssertEqual(d.id, "b3")
            XCTAssertEqual(d.props.text, "NEW")
            XCTAssertEqual(d.props.variant, "soft")
        } else {
            XCTFail("Expected badge component")
        }
    }

    // MARK: - Default variant (nil)

    func testBadgeDefaultVariant() throws {
        let component = PaywallComponent.badge(BadgeComponentData(
            id: "b4",
            props: BadgeComponentData.BadgeProps(text: "POPULAR")
        ))
        let decoded = try roundTrip(component)
        if case .badge(let d) = decoded {
            XCTAssertEqual(d.id, "b4")
            XCTAssertEqual(d.props.text, "POPULAR")
            XCTAssertNil(d.props.variant)
        } else {
            XCTFail("Expected badge component")
        }
    }

    // MARK: - JSON decode

    func testBadgeDecodeFromJSON() throws {
        let json = """
        {"type": "badge", "id": "b5", "props": {"text": "HOT", "variant": "filled"}}
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)
        if case .badge(let d) = component {
            XCTAssertEqual(d.props.text, "HOT")
            XCTAssertEqual(d.props.variant, "filled")
        } else {
            XCTFail("Expected badge component")
        }
    }
}
