import Foundation

struct City {
    var name: String
    var country: String
}

extension City {
    static func loadAll() -> [City] {
        return [
            City(name: "Berlin", country: "Germany"),
            City(name: "Beijing", country: "China"),
            City(name: "Paris", country: "France"),
            City(name: "San Francisco", country: "USA"),
            City(name: "Athens", country: "Greece"),
            City(name: "Oslo", country: "Norway"),
            City(name: "Stockholm", country: "Sweden"),
            City(name: "New York City", country: "USA")
        ]
    }
}
