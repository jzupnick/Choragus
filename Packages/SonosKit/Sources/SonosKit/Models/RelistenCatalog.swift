import Foundation

public enum RelistenCatalog {
    public static func datedYears(_ items: [BrowseItem]) -> [BrowseItem] {
        items.map { item in
            let parts = item.objectID.split(separator: ":")
            guard parts.count >= 5, parts[2] == "Year", let year = Int(parts.last ?? ""),
                  (1900...2100).contains(year),
                  let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: 1, day: 1)) else { return item }
            var result = item
            result.releaseDate = date
            return result
        }
    }

    public static func sortYears(_ items: [BrowseItem], order: BrowseSortOption) -> [BrowseItem] {
        guard order == .newest || order == .oldest else { return order.apply(items) }
        let years = order.apply(items.filter { $0.releaseDate != nil })
        var index = 0
        return items.map { item in
            guard item.releaseDate != nil else { return item }
            defer { index += 1 }
            return years[index]
        }
    }
}
