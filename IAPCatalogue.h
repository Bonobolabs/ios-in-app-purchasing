#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol IAPCatalogueDelegate;

@interface IAPCatalogue : NSObject<SKProductsRequestDelegate>
- (void)load:(id<IAPCatalogueDelegate>) delegate;
- (void)cancel;
@end

@protocol IAPCatalogueDelegate <NSObject>

- (void)iapCatalogue:(IAPCatalogue*)catalogue didLoadProductsFromCache:(NSArray*)products;
- (void)iapCatalogue:(IAPCatalogue*)catalogue didLoadProducts:(NSArray*)products;
- (void)iapCatalogueDidFinishLoading:(IAPCatalogue*)catalogue;
- (void)iapCatalogue:(IAPCatalogue*)catalogue didFailWithError:(NSError*)error;

@end
