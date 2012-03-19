#import <Foundation/Foundation.h>

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

@interface IAPProduct : NSObject
@property (nonatomic, readonly, strong) NSString* identifier;
@property (nonatomic, readonly, strong) NSDecimalNumber* price;
@property (nonatomic, readonly, assign) BOOL isLoading;
@property (nonatomic, readonly, assign) BOOL isReadyForSale;
@property (nonatomic, readonly, assign) BOOL isPurchased;
@property (nonatomic, readonly, assign) BOOL isError;
@property (nonatomic, readonly, assign) BOOL isPurchasing;
@property (nonatomic, readonly, assign) BOOL isRestored;
@property (nonatomic, readonly, strong) const NSString* state;

- (id)initWithCatalogue:(IAPCatalogue*)catalogue identifier:(NSString*)identifier;
- (BOOL)identifierEquals:(NSString*)identifier;

- (void)updateWithSKProduct:(SKProduct*)skProduct;
- (void)updateWithSKPaymentTransaction:(SKPaymentTransaction*)skTransaction;
- (void)updateWithSKPayment:(SKPayment*)skPayment;
- (void)purchase;
@end
