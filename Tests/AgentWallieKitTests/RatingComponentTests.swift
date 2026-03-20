import XCTest
@testable import AgentWallieKit

final class RatingComponentTests: XCTestCase {

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Full props round-trip

    func testRatingFullPropsRoundTrip() throws {
        let component = PaywallComponent.rating(RatingComponentData(
            id: "r1",
            props: RatingComponentData.RatingProps(value: 4.8, count: 12500, label: "ratings", maxStars: 5)
        ))
        let decoded = try roundTrip(component)
        if case .rating(let d) = decoded {
            XCTAssertEqual(d.id, "r1")
            XCTAssertEqual(d.props.value, 4.8)
            XCTAssertEqual(d.props.count, 12500)
            XCTAssertEqual(d.props.label, "ratings")
            XCTAssertEqual(d.props.maxStars, 5)
            XCTAssertEqual(d.type, "rating")
        } else {
            XCTFail("Expected rating component")
        }
    }

    // MARK: - Defaults (only required value)

    func testRatingDefaultsRoundTrip() throws {
        let component = PaywallComponent.rating(RatingComponentData(
            id: "r2",
            props: RatingComponentData.RatingProps(value: 3.5)
        ))
        let decoded = try roundTrip(component)
        if case .rating(let d) = decoded {
            XCTAssertEqual(d.id, "r2")
            XCTAssertEqual(d.props.value, 3.5)
            XCTAssertNil(d.props.count)
            XCTAssertNil(d.props.label)
            XCTAssertNil(d.props.maxStars)
        } else {
            XCTFail("Expected rating component")
        }
    }

    // MARK: - Custom max_stars

    func testRatingCustomMaxStars() throws {
        let component = PaywallComponent.rating(RatingComponentData(
            id: "r3",
            props: RatingComponentData.RatingProps(value: 8.5, maxStars: 10)
        ))
        let decoded = try roundTrip(component)
        if case .rating(let d) = decoded {
            XCTAssertEqual(d.props.value, 8.5)
            XCTAssertEqual(d.props.maxStars, 10)
        } else {
            XCTFail("Expected rating component")
        }
    }

    // MARK: - JSON decode

    func testRatingDecodeFromJSON() throws {
        let json = """
        {"type": "rating", "id": "r4", "props": {"value": 4.5, "count": 999, "max_stars": 5}}
        """
        let data = json.data(using: .utf8)!
        let component = try JSONDecoder().decode(PaywallComponent.self, from: data)
        if case .rating(let d) = component {
            XCTAssertEqual(d.props.value, 4.5)
            XCTAssertEqual(d.props.count, 999)
            XCTAssertEqual(d.props.maxStars, 5)
        } else {
            XCTFail("Expected rating component")
        }
    }
}
