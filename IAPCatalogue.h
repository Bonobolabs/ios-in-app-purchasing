#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class IAPProduct;
@protocol IAPCatalogueDelegate;

@interface IAPCatalogue : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, readonly, strong) NSDate* lastUpdatedAt;

- (void)update:(id<IAPCatalogueDelegate>) delegate;
- (void)cancel;
- (IAPProduct*)productForIdentifier:(NSString*)identifier;
- (void)purchaseProduct:(IAPProduct*)product;
- (void)restoreProduct:(IAPProduct*)product;
@end

@protocol IAPCatalogueDelegate <NSObject>
@optional
- (void)iapCatalogueDidUpdate:(IAPCatalogue*)catalogue;
- (void)iapCatalogueDidFinishUpdating:(IAPCatalogue*)catalogue;
- (void)iapCatalogue:(IAPCatalogue*)catalogue updateFailedWithError:(NSError*)error;

@end
