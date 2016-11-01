import CoreGraphics

extension CGFloat {
    func divided(by number: CGFloat, margin: CGFloat) -> CGFloat {
        let totalMargin = margin * (number + 1)
        let space = self - totalMargin
        return space / number
    }
}
