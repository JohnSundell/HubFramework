import Foundation
import HubFramework

class PromotionComponent: NSObject, HUBComponentWithImageHandling, HUBComponentViewObserver {
    var view: UIView?
    lazy var imageView = UIImageView()
    lazy var label = UILabel()

    var layoutTraits: Set<HUBComponentLayoutTrait> {
        return [.fullWidth, .stackable]
    }

    func loadView() {
        label.font = .boldSystemFont(ofSize: 40)
        label.textColor = .white
        imageView.addSubview(label)
        view = imageView
    }

    func preferredViewSize(forDisplaying model: HUBComponentModel, containerViewSize: CGSize) -> CGSize {
        return CGSize(width: containerViewSize.width, height: containerViewSize.width / 3)
    }

    func prepareViewForReuse() {
        imageView.image = nil
        label.text = nil
    }

    func configureView(with model: HUBComponentModel, containerViewSize: CGSize) {
        label.text = model.title
        label.sizeToFit()
    }
    
    func preferredSizeForImage(from imageData: HUBComponentImageData, model: HUBComponentModel, containerViewSize: CGSize) -> CGSize {
        return preferredViewSize(forDisplaying: model, containerViewSize: containerViewSize)
    }
    
    func updateView(forLoadedImage image: UIImage, from imageData: HUBComponentImageData, model: HUBComponentModel, animated: Bool) {
        imageView.setImage(image, animated: animated)
    }
    
    func viewWillAppear() {
        // No-op
    }
    
    func viewDidResize() {
        label.center = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
    }
}
