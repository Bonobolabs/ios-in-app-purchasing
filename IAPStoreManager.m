#import "IAPStoreManager.h"
#import "IAPCatalogue.h"

@interface IAPStoreManager()
@property (nonatomic, strong) IAPCatalogue* catalogue;
@end

@implementation IAPStoreManager
@synthesize catalogue = _catalogue;

static NSTimeInterval autoUpdateInterval = 30; // Check the catalogue for expiry every 30 seconds. Need to check this often in case the application was sent into the background.
static NSTimeInterval expiryInterval = 60 * 60 * 24; // 24 hours.

+ (IAPStoreManager *)sharedInstance
{
    static IAPStoreManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[IAPStoreManager alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.catalogue = [[IAPCatalogue alloc] init];
    }
    
    return self;
}

- (void)autoUpdate {
    [NSTimer scheduledTimerWithTimeInterval:autoUpdateInterval target:self selector:@selector(checkCatalogueNeedsUpdating) userInfo:nil repeats:YES];
    [self checkCatalogueNeedsUpdating];
}

- (void)checkCatalogueNeedsUpdating {
    if ([self hasCatalogueExpired:self.catalogue]) {
        [self.catalogue update:self];
    }
}

- (BOOL)hasCatalogueExpired:(IAPCatalogue*)catalogue {
    NSDate* lastUpdatedAt = catalogue.lastUpdatedAt;
    
    if (!lastUpdatedAt) {
        return YES;
    }
    
    NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval secondsSinceLastUpdate = [lastUpdatedAt timeIntervalSinceDate:now];
    BOOL expired = secondsSinceLastUpdate > expiryInterval;
    return expired;
}

- (IAPProduct*)productForIdentifier:(NSString*)identifier {
    return [self.catalogue productForIdentifier:identifier];
}

- (void)restoreAllProducts {
    [self.catalogue restoreAllProducts];
}

- (NSDictionary*)products {
    return self.catalogue.products;
}

@end
