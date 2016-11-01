import Foundation
import HubFramework

class CircularComponent: NSObject, HUBComponentWithImageHandling {
    var view: UIView?
    lazy var imageView = UIImageView()

    var layoutTraits: Set<HUBComponentLayoutTrait> {
        return [.compactWidth]
    }

    func loadView() {
        self.view = imageView
    }

    func preferredViewSize(forDisplaying model: HUBComponentModel, containerViewSize: CGSize) -> CGSize {
        let metric = containerViewSize.width.divided(by: 4, margin: ComponentLayoutManager.margin)
        return CGSize(width: metric, height: metric)
    }

    func prepareViewForReuse() {
        imageView.image = nil
    }

    func configureView(with model: HUBComponentModel, containerViewSize: CGSize) {
        imageView.backgroundColor = .gray
        imageView.layer.cornerRadius = preferredViewSize(forDisplaying: model, containerViewSize: containerViewSize).width / 2
        imageView.clipsToBounds = true
    }

    func preferredSizeForImage(from imageData: HUBComponentImageData, model: HUBComponentModel, containerViewSize: CGSize) -> CGSize {
        // Return the size you'd prefer an image to be, or CGSizeZero for non-supported types.
        switch imageData.type {
        case .main, .background, .custom:
            return preferredViewSize(forDisplaying: model, containerViewSize: containerViewSize);
        }
    }

    func updateView(forLoadedImage image: UIImage, from imageData: HUBComponentImageData, model: HUBComponentModel, animated: Bool) {
        imageView.setImage(image, animated: animated)
    }
}
