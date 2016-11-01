import Foundation

extension Array {
    func split() -> [ArraySlice<Element>] {
        guard count > 1 else {
            return [self[0 ..< count]]
        }
        
        let splitIndex = count / 2
        
        return [
            self[0 ..< splitIndex],
            self[splitIndex ..< count]
        ]
    }
}
