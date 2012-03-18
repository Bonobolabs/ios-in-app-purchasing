#import <Foundation/Foundation.h>

@class SKProduct;

@interface IAPProduct : NSObject
@property (nonatomic, readonly, strong) NSString* identifier;
@property (nonatomic, readonly, strong) NSDecimalNumber* price;
@property (nonatomic, readonly, assign) BOOL isLoading;

- (id)initWithIdentifier:(NSString*)identifier;
- (BOOL)identifierEquals:(NSString*)identifier;

- (void)updateWithSKProduct:(SKProduct*)skProduct;
@end
