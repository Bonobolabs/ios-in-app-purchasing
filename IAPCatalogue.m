#import "IAPCatalogue.h"
#import "IAPProduct+Friend.h"

@interface IAPCatalogue()
@property (nonatomic, readwrite, strong) NSDate* lastUpdatedAt;
@property (nonatomic, strong) SKProductsRequest* request;
@property (nonatomic, weak) id<IAPCatalogueDelegate> delegate;
@property (nonatomic, readwrite, strong) NSDictionary* products;
@property (nonatomic, strong) NSMutableDictionary* skProducts;
@property (nonatomic, strong) SKPaymentQueue* paymentQueue;
@end

@implementation IAPCatalogue
@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize products = _products;
@synthesize lastUpdatedAt = _lastUpdatedAt;
@synthesize skProducts = _skProducts;
@synthesize paymentQueue;

static NSString* infoPlist = @"IAPInfo";
static NSString* productsPlistKey = @"products";

- (id)init {
    self = [super init];
    
    if (self) {
        [self initProductsWithPlist];
        [self initSKProducts];
        [self setupPaymentQueue];
    }
    
    return self;
}

- (void)dealloc {
    [self tearDownPaymentQueue];
}

- (void)setupPaymentQueue {
    self.paymentQueue = [SKPaymentQueue defaultQueue];
    [self.paymentQueue addTransactionObserver:self];
}

- (void)tearDownPaymentQueue {
    [self.paymentQueue removeTransactionObserver:self];
}

- (void)update:(id<IAPCatalogueDelegate>)delegate { 
    [self cancel];
    self.delegate = delegate; 
    NSSet* productIdentifiers = [NSSet setWithArray:self.products.allKeys];
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    request.delegate = self;
    [request start];
    self.request = request;    
}

- (void)cancel {
    self.delegate = nil;
    if (self.request)
        [self.request cancel];
    self.request = nil;
}

- (IAPProduct*)productForIdentifier:(NSString*)identifier {
    return [self.products objectForKey:identifier];
}

- (SKProduct*)skProductForIdentifier:(NSString*)identifier {
    SKProduct* skProduct = nil;
    skProduct = [self.skProducts valueForKey:identifier];
    return skProduct;
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
        IAPProduct* product = [[IAPProduct alloc] initWithCatalogue:self identifier:productIdentifier settings:[NSUserDefaults standardUserDefaults]];
        [products setObject:product forKey:productIdentifier];
    }
    
    self.products = products;
}

- (void)initSKProducts {
    self.skProducts = [NSMutableDictionary dictionary];
}

- (void)updateProducts:(NSArray*)skProducts {
    [self.skProducts removeAllObjects];
    for (SKProduct* skProduct in skProducts) {
        IAPProduct* product = [self.products objectForKey:skProduct.productIdentifier];
        if (product) {
            [product updateWithSKProduct:skProduct];
        }     
        [self.skProducts setObject:skProduct forKey:skProduct.productIdentifier];
    }
    if ([skProducts count] == [self.products count]) {
        self.lastUpdatedAt = [NSDate dateWithTimeIntervalSinceNow:0];
    }
}

- (void)purchaseProduct:(IAPProduct*)product {
    SKProduct* skProduct = [self skProductForIdentifier:product.identifier];
    if (!skProduct) {
        [NSException raise:@"A product can't be purchased before it has been retrieved from Apple." format:@"Call [IAPCatalogue update:] to retrieve the product from Apple."];
    }
    else {
        [self purchaseProduct:product skProduct:skProduct];
    }
}
        
- (void)purchaseProduct:(IAPProduct*)product skProduct:(SKProduct*)skProduct {
    SKPayment *payment = [SKPayment paymentWithProduct:skProduct];
    [product updateWithSKPayment:payment];
    [self.paymentQueue addPayment:payment];
}

- (void)restoreProduct:(IAPProduct*)product {
    [self.paymentQueue restoreCompletedTransactions];
    [product restoreStarted];
}

- (void)restoreAllProducts {
    [self.paymentQueue restoreCompletedTransactions];
    for (NSString* key in self.products) {
        IAPProduct* product = [self.products valueForKey:key];
        [product restoreStarted];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        SKPayment* payment = transaction.payment;
        NSString* identifier = payment.productIdentifier;
        
        IAPProduct* product = [self productForIdentifier:identifier];
        if (product) {
            [product updateWithSKPaymentTransaction:transaction];
        }
        if (transaction.transactionState != SKPaymentTransactionStatePurchasing)
            [self.paymentQueue finishTransaction:transaction];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    for (IAPProduct* product in [self.products allValues]) {
        [product restoreFailedWithError:error];
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    for (IAPProduct* product in [self.products allValues]) {
        [product restoreEnded];
    }    
}

@end
