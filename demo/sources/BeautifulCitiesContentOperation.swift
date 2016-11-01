import Foundation
import HubFramework

class BeautifulCitiesContentOperation: NSObject, HUBContentOperation {
    weak var delegate: HUBContentOperationDelegate?

    func perform(forViewURI viewURI: URL, featureInfo: HUBFeatureInfo, connectivityState: HUBConnectivityState, viewModelBuilder: HUBViewModelBuilder, previousError: Error?) {
        
        Image.loadAll().enumerated().forEach { (index, image) in
            let imageBuilder = viewModelBuilder.builderForBodyComponentModel(withIdentifier: "image-\(index)")
            imageBuilder.componentName = DefaultComponentNames.image
            imageBuilder.mainImageURL = image.url
        }
        
        City.loadAll().split().enumerated().forEach { (sliceIndex, slice) in
            slice.enumerated().forEach { index, city in
                let rowBuilder = viewModelBuilder.builderForBodyComponentModel(withIdentifier: "city-\(sliceIndex)-\(index)")
                rowBuilder.title = city.name
                rowBuilder.subtitle = city.country
            }
            
            if sliceIndex == 0 {
                User.loadAll().enumerated().forEach { (index, user) in
                    let imageBuilder = viewModelBuilder.builderForBodyComponentModel(withIdentifier: "user-\(index)")
                    imageBuilder.title = user.name
                    imageBuilder.mainImageURL = user.imageUrl
                    imageBuilder.componentName = DefaultComponentNames.circular
                }
            }
        }
        
        delegate?.contentOperationDidFinish(self)
    }
}
