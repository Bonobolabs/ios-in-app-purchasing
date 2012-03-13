#import "IAPCatalogue.h"

@interface IAPCatalogue()
@property(nonatomic, strong) SKProductsRequest* request;
@property(nonatomic, weak) id<IAPCatalogueDelegate> delegate;
@property(nonatomic, strong) NSArray* productCache;
@end

@implementation IAPCatalogue
@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize productCache;

- (id)init {
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

- (void)load:(id<IAPCatalogueDelegate>)delegate {    
    self.delegate = delegate; 
    
    NSSet* productIdentifiers = [NSSet setWithObjects:
                                 @"com.bonobolabs.iboost.progauge",
                                 nil];
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    request.delegate = self;
    [request start];
    self.request = request;
    
    if (self.productCache && 
        [delegate respondsToSelector:@selector(inAppCatalogue:didLoadProductsFromCache:)]) {
        [delegate inAppCatalogue:self didLoadProductsFromCache:self.productCache];
    }
}

- (void)cancel {
    self.delegate = nil;
    [self.request cancel];
    self.request = nil;
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    id delegate = self.delegate;
    self.productCache = response.products;
    
    if ([delegate respondsToSelector:@selector(inAppCatalogue:didLoadProducts:)]) {
        [delegate inAppCatalogue:self didLoadProducts:self.productCache];
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    id delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(inAppCatalogueDidFinishLoading:)]) {
        [delegate inAppCatalogueDidFinishLoading:self];
    }    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    id delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(inAppCatalogue:didFailWithError:)]) {
        [delegate inAppCatalogue:self didFailWithError:error];
    }
    
    if ([delegate respondsToSelector:@selector(inAppCatalogueDidFinishLoading:)]) {
        [delegate inAppCatalogueDidFinishLoading:self];
    }    
}


@end
