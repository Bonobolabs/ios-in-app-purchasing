#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol IAPCatalogueDelegate;

@interface IAPCatalogue : NSObject<SKProductsRequestDelegate>
- (void)load:(id<IAPCatalogueDelegate>) delegate;
- (void)cancel;
@end

@protocol IAPCatalogueDelegate <NSObject>

- (void)inAppCatalogue:(IAPCatalogue*)catalogue didLoadProductsFromCache:(NSArray*)products;
- (void)inAppCatalogue:(IAPCatalogue*)catalogue didLoadProducts:(NSArray*)products;
- (void)inAppCatalogueDidFinishLoading:(IAPCatalogue*)catalogue;
- (void)inAppCatalogue:(IAPCatalogue*)catalogue didFailWithError:(NSError*)error;

@end
