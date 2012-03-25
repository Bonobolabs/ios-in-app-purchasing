#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (PriceWithCurrency)
@property (nonatomic, readonly) NSString* priceWithCurrency;
@end