import XCTest
@testable import SonosKit

final class RelistenCatalogTests: XCTestCase {
    func testYearsSortWithoutMovingOtherFolders() {
        let rows = [
            BrowseItem(id: "smapi:270:Year:band:latest", title: "Latest Tapes", itemClass: .container),
            BrowseItem(id: "smapi:270:TopShows:band", title: "Top Shows", itemClass: .container),
            BrowseItem(id: "smapi:270:Year:band:2022", title: "2022 (1 show)", itemClass: .container),
            BrowseItem(id: "smapi:270:Year:band:2026", title: "2026 (3 shows)", itemClass: .container),
        ]
        let dated = RelistenCatalog.datedYears(rows)
        XCTAssertEqual(RelistenCatalog.sortYears(dated, order: .newest).map(\.title), ["Latest Tapes", "Top Shows", "2026 (3 shows)", "2022 (1 show)"])
        XCTAssertEqual(RelistenCatalog.sortYears(dated, order: .oldest).map(\.title), rows.map(\.title))
        XCTAssertTrue(BrowseSortOption.available(for: dated).contains(.newest))
    }
}
