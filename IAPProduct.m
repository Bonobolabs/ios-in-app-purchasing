#import "IAPProduct.h"
#import <StoreKit/StoreKit.h>

@interface IAPProduct()
@property (nonatomic, readwrite, strong) NSString* identifier;
@property (nonatomic, readwrite, strong) NSDecimalNumber* price;
@end

@implementation IAPProduct
@synthesize identifier = _identifier;
@synthesize price = _price;

- (id)initWithIdentifier:(NSString*)identifier {
    self = [super init];
    
    if (self) {
        self.identifier = identifier;
    }
    
    return self;
}

- (void)updateWithSKProduct:(SKProduct*)skProduct {
    self.price = skProduct.price;
}

- (BOOL)identifierEquals:(NSString*)identifier {
    return identifier && [identifier isEqualToString:self.identifier];
}

- (BOOL)isLoading {
    return self.price == nil;
}

//loading => loaded
//loading => error
//error => loading
//loaded => purchasing
//loaded => restoring
//purchasing => purchased
//purchasing => purchasing failed
//purchasing failed => purchasing
//restoring => restored

@end
