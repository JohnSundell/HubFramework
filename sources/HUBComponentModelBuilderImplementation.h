#import "HUBComponentModelBuilder.h"
#import "HUBModifiable.h"
#import "HUBHeaderMacros.h"

@protocol HUBJSONSchema;
@protocol HUBIconImageResolver;
@class HUBComponentDefaults;
@class HUBComponentModelImplementation;
@class HUBComponentImageDataBuilderImplementation;

NS_ASSUME_NONNULL_BEGIN

/// Concrete implementation of the `HUBComponentModelBuilder` API
@interface HUBComponentModelBuilderImplementation : NSObject <HUBComponentModelBuilder, HUBModifiable, NSCopying>

/**
 *  Build an array of component models from a collection of builders
 *
 *  @param builders The builders to use to build component models. The keys should be model identifiers.
 *  @param identifierOrder An ordered array of identifiers of the models to build. This will determine the build order.
 *
 *  The `preferredIndex` property of each builder will also be taken into account, so the supplied `identifierOrder` is
 *  only used as a default order for the returned array of component models.
 */
+ (NSArray<HUBComponentModelImplementation *> *)buildComponentModelsUsingBuilders:(NSDictionary<NSString *, HUBComponentModelBuilderImplementation *> *)builders
                                                                  identifierOrder:(NSArray<NSString *> *)identifierOrder;

/**
 *  Initialize an instance of this class with its required dependencies
 *
 *  @param modelIdentifier The identifier of the model to be built. If `nil`, an `NSUUID`-based identifier will be used.
 *  @param featureIdentifier The identifier of the feature that the component will be presented in
 *  @param JSONSchema The schema to use to parse data from any added JSON object
 *  @param componentDefaults The default component values that should be used as initial values for this builder
 *  @param iconImageResolver The resolver to use to convert icons into renderable images
 *  @param mainImageDataBuilder Any specific image data builder that the object should use for its main image.
 *  @param backgroundImageDataBuilder Any specific image data builder that the object should use for its background image.
 */
- (instancetype)initWithModelIdentifier:(nullable NSString *)modelIdentifier
                      featureIdentifier:(NSString *)featureIdentifier
                             JSONSchema:(id<HUBJSONSchema>)JSONSchema
                      componentDefaults:(HUBComponentDefaults *)componentDefaults
                      iconImageResolver:(nullable id<HUBIconImageResolver>)iconImageResolver
                   mainImageDataBuilder:(nullable HUBComponentImageDataBuilderImplementation *)mainImageDataBuilder
             backgroundImageDataBuilder:(nullable HUBComponentImageDataBuilderImplementation *)backgroundImageDataBuilder HUB_DESIGNATED_INITIALIZER;

/**
 *  Build an instance of `HUBComponentModelImplementation` from the data contained in this builder
 *
 *  @param index The index that the produced model will have, either within its parent or within the root list
 */
- (HUBComponentModelImplementation *)buildForIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END