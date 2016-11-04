import UIKit

struct User {
    var name: String
    var image: UIImage
}

extension User {
    static func loadAll() -> [User] {
        return [
            User(name: "Julia", image: UIImage(named: "user-0")!),
            User(name: "Mathew", image: UIImage(named: "user-1")!),
            User(name: "Caroline", image: UIImage(named: "user-2")!),
            User(name: "David", image: UIImage(named: "user-3")!)
        ]
    }
}
