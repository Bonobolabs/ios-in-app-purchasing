#import <Foundation/Foundation.h>

@class SKProduct;

@interface IAPProduct : NSObject
@property (nonatomic, readonly, strong) NSString* identifier;
@property (nonatomic, readonly, strong) NSDecimalNumber* price;
@property (nonatomic, readonly, assign) BOOL isLoading;
@property (nonatomic, readonly, assign) BOOL isReadyForSale;
@property (nonatomic, readonly, assign) BOOL isPurchased;
@property (nonatomic, readonly, strong) NSString* state;

- (id)initWithIdentifier:(NSString*)identifier;
- (BOOL)identifierEquals:(NSString*)identifier;

- (void)updateWithSKProduct:(SKProduct*)skProduct;
@end
