import Foundation

struct Image {
    var url: URL
}

extension Image {
    static func loadAll() -> [Image] {
        return [
            Image(url: URL(string: "http://localhost:8000/images/tokyo.jpg")!),
            Image(url: URL(string: "http://localhost:8000/images/gothenburg.jpg")!)
        ]
    }
}
