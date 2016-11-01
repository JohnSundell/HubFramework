import Foundation

struct User {
    var name: String
    var imageUrl: URL
}

extension User {
    static func loadAll() -> [User] {
        return [
            User(name: "Julia", imageUrl: URL(string: "http://localhost:8000/images/user-0.jpg")!),
            User(name: "Mathew", imageUrl: URL(string: "http://localhost:8000/images/user-1.jpg")!),
            User(name: "Caroline", imageUrl: URL(string: "http://localhost:8000/images/user-2.jpg")!),
            User(name: "David", imageUrl: URL(string: "http://localhost:8000/images/user-3.jpg")!)
        ]
    }
}
