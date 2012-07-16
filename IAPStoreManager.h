#import <Foundation/Foundation.h>
#import "IAPCatalogue.h"

@interface IAPStoreManager : NSObject<IAPCatalogueDelegate>
@property (nonatomic, readonly) NSDictionary* products;
+ (IAPStoreManager *)sharedInstance;
- (void)autoUpdate;
- (IAPProduct*)productForIdentifier:(NSString*)identifier;
- (void)restoreAllProducts;
@end
