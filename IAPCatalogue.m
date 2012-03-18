#import "IAPCatalogue.h"
#import "IAPProduct.h"

@interface IAPCatalogue()
@property (nonatomic, readwrite, strong) NSDate* lastUpdatedAt;
@property(nonatomic, strong) SKProductsRequest* request;
@property(nonatomic, weak) id<IAPCatalogueDelegate> delegate;
@property(nonatomic, strong) NSDictionary* products;

- (void)initProductsWithPlist;
- (void)updateProducts:(NSArray*)skProducts;
@end

@implementation IAPCatalogue
@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize products = _products;
@synthesize lastUpdatedAt = _lastUpdatedAt;

static NSString* infoPlist = @"IAPInfo";
static NSString* productsPlistKey = @"products";

- (id)init {
    self = [super init];
    
    if (self) {
        [self initProductsWithPlist];
    }
    
    return self;
}

- (void)update:(id<IAPCatalogueDelegate>)delegate {    
    self.delegate = delegate; 
    NSSet* productIdentifiers = [NSSet setWithArray:self.products.allKeys];
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    request.delegate = self;
    [request start];
    self.request = request;    
}

- (void)cancel {
    self.delegate = nil;
    [self.request cancel];
    self.request = nil;
}

- (IAPProduct*)productForIdentifier:(NSString*)identifier {
    return [self.products objectForKey:identifier];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    id delegate = self.delegate;
    [self updateProducts:response.products];
    
    if ([delegate respondsToSelector:@selector(iapCatalogueDidUpdate:)]) {
        [delegate iapCatalogueDidUpdate:self];
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    id delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(iapCatalogueDidFinishUpdating:)]) {
        [delegate iapCatalogueDidFinishUpdating:self];
    }    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    id delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(iapCatalogue:updateFailedWithError:)]) {
        [delegate iapCatalogue:self updateFailedWithError:error];
    }
    
    if ([delegate respondsToSelector:@selector(iapCatalogueDidFinishUpdating:)]) {
        [delegate iapCatalogueDidFinishUpdating:self];
    }    
}

- (void)initProductsWithPlist {
    NSMutableDictionary* products = [NSMutableDictionary dictionary];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:infoPlist ofType:@"plist"];
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSArray* productIdentifiers = [plist objectForKey:productsPlistKey];
    for (NSString* productIdentifier in productIdentifiers) {
        IAPProduct* product = [[IAPProduct alloc] initWithIdentifier:productIdentifier];
        [products setObject:product forKey:productIdentifier];
    }
    
    self.products = products;
}

- (void)updateProducts:(NSArray*)skProducts {
    for (SKProduct* skProduct in skProducts) {
        for (IAPProduct* product in [self.products allValues]) {
            if ([product identifierEquals:skProduct.productIdentifier]) {
                [product updateWithSKProduct:skProduct];
            }
        }
    }
    self.lastUpdatedAt = [NSDate dateWithTimeIntervalSinceNow:0];
}

//- (void)purchaseProduct:(IAPProduct)product {
//    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
//    [[SKPaymentQueue defaultQueue] addPayment:payment];
//}

@end
