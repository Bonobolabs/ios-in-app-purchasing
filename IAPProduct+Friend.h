#import "IAPProduct.h"

@class SKProduct;
@class SKPaymentTransaction;
@class SKPayment;
@class IAPCatalogue;

extern const NSString* kStateLoading;
extern const NSString* kStateReadyForSale;
extern const NSString* kStatePurchased;
extern const NSString* kStatePurchasing;
extern const NSString* kStateError;
extern const NSString* kStateRestored;

@interface IAPProduct(Friend)
@property (nonatomic, readonly, strong) const NSString* state;

- (id)initWithCatalogue:(IAPCatalogue*)catalogue identifier:(NSString*)identifier settings:(NSUserDefaults*)settings;
- (BOOL)identifierEquals:(NSString*)identifier;
- (void)updateWithSKProduct:(SKProduct*)skProduct;
- (void)updateWithSKPaymentTransaction:(SKPaymentTransaction*)skTransaction;
- (void)updateWithSKPayment:(SKPayment*)skPayment;
- (void)restoreStarted;
- (void)restoreFailedWithError:(NSError*)error;
- (void)restoreEnded;

@end


