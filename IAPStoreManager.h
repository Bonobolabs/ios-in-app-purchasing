#import <Foundation/Foundation.h>
#import "IAPCatalogue.h"

@interface IAPStoreManager : NSObject<IAPCatalogueDelegate>
+ (IAPStoreManager *)sharedInstance;
- (void)autoUpdate;
- (IAPProduct*)productForIdentifier:(NSString*)identifier;
@end
