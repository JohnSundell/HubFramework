import Foundation

struct Image {
    var url: URL
}

extension Image {
    static func loadAll() -> [Image] {
        return [
            Image(url: URL(string: "https://spotify.github.io/HubFramework/resources/getting-started-tokyo.jpg")!),
            Image(url: URL(string: "https://spotify.github.io/HubFramework/resources/getting-started-gothenburg.jpg")!)
        ]
    }
}
