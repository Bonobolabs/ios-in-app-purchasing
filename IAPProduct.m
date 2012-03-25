#import "IAPProduct.h"
#import <StoreKit/StoreKit.h>
#import "FSMMachine.h"
#import "IAPCatalogue.h"
#import "SKProduct+PriceWithCurrency.h"

@interface IAPProduct()
@property (nonatomic, readwrite, strong) NSString* identifier;
@property (nonatomic, strong) IAPCatalogue* catalogue;
@property (nonatomic, readwrite, strong) NSString* price;
@property (nonatomic, strong) FSMMachine* stateMachine;
@property (nonatomic, readwrite, strong) const NSString* state;
<<<<<<< HEAD
@property (nonatomic, strong) NSMutableArray* observers;
@property (nonatomic, readwrite, strong) NSUserDefaults* settings;
=======
- (void)loadStateMachine:(const NSString*)initialState;
- (void)unloadStateMachine;
>>>>>>> eaf57e05be71113a0bae198d6aa46f42b73c3c69
@end

@implementation IAPProduct
@synthesize identifier = _identifier;
@synthesize catalogue = _catalogue;
@synthesize price = _price;
@synthesize stateMachine;
@synthesize state = _state;
@synthesize observers;
@synthesize settings = _settings;

// State machine states and events 
const NSString* kStateLoading = @"Loading";
const NSString* kStateReadyForSale = @"ReadyForSale";
const NSString* kStatePurchased = @"Purchased";
const NSString* kStatePurchasing = @"Purchasing";
const NSString* kStateRestored = @"Restored";
const NSString* kStateError = @"Error";
const NSString* kEventSetPrice = @"SetPrice";
const NSString* kEventSetPurchased = @"SetPurchased";
const NSString* kEventSetError = @"SetError";
const NSString* kEventSetRestored = @"SetRestored";
const NSString* kEventSetPurchasing = @"SetPurchasing";
const NSString* kEventRecoverToReadyForSale = @"RecoverToReadyForSale";
const NSString* kEventRecoverToLoading = @"RecoverToLoading";

- (id)initWithCatalogue:(IAPCatalogue*)catalogue identifier:(NSString*)identifier settings:(NSUserDefaults*)settings {
    self = [super init];
    
    if (self) {
        self.identifier = identifier;
        self.catalogue = catalogue;
        [self loadStateMachine: kStateLoading];
        self.observers = [NSMutableArray array];
        self.settings = settings;
        [self restore];
    }
    
    return self;
}

- (void)dealloc {
    [self unloadStateMachine];
}

- (void)loadStateMachine:(const NSString*)initialState { 
    [self unloadStateMachine];
    self.stateMachine = [[FSMMachine alloc] initWithState:initialState];
    [self.stateMachine addTransition:kEventSetPrice startState:kStateLoading endState:kStateReadyForSale];
    [self.stateMachine addTransition:kEventSetPrice startState:kStateReadyForSale endState:kStateReadyForSale];
    [self.stateMachine addTransition:kEventSetPrice startState:kStatePurchased endState:kStatePurchased];
    [self.stateMachine addTransition:kEventSetPrice startState:kStateRestored endState:kStateRestored];
    [self.stateMachine addTransition:kEventRecoverToReadyForSale startState:kStateError endState:kStateReadyForSale];
    [self.stateMachine addTransition:kEventRecoverToLoading startState:kStateError endState:kStateLoading];
    [self.stateMachine addTransition:kEventSetPurchasing startState:kStateReadyForSale endState:kStatePurchasing];
    [self.stateMachine addTransition:kEventSetError startState:kStateLoading endState:kStateError];
    [self.stateMachine addTransition:kEventSetError startState:kStatePurchasing endState:kStateError];
    [self.stateMachine addTransition:kEventSetPurchased startState:kStatePurchasing endState:kStatePurchased];
    [self.stateMachine addTransition:kEventSetRestored startState:kStatePurchasing endState:kStateRestored];
    
    [self.stateMachine addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    self.state = self.stateMachine.state;
}

- (void)unloadStateMachine {
    if (self.stateMachine) 
        [self.stateMachine removeObserver:self forKeyPath:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.stateMachine) {
        if ([@"state" isEqualToString:keyPath]) {
            bool stateChanged = self.state != self.stateMachine.state;
            self.state = self.stateMachine.state;
            if (stateChanged) {
                [self notifyObserversOfStateChange];
            }
        }
    }
}

- (void)updateWithSKProduct:(SKProduct*)skProduct {
    self.price = skProduct.priceWithCurrency;
    [self.stateMachine applyEvent:kEventSetPrice];
    [self save];
}

- (void)updateWithSKPaymentTransaction:(SKPaymentTransaction*)skTransaction {
    if (self.state != kStatePurchasing)
        return;
    
    switch (skTransaction.transactionState) {
        case SKPaymentTransactionStatePurchased: {
            [self.stateMachine applyEvent:kEventSetPurchased];
            break;
        }
        case SKPaymentTransactionStateFailed: {
            [self.stateMachine applyEvent:kEventSetError];
            [self.stateMachine applyEvent:kEventRecoverToReadyForSale];
            break;
        }
        case SKPaymentTransactionStateRestored: {
            [self.stateMachine applyEvent:kEventSetRestored];
            break;
        }
    }
    [self save];
}

- (void)updateWithSKPayment:(SKPayment*)skPayment {
    [self.stateMachine applyEvent:kEventSetPurchasing];
    [self save];
}

- (NSString*)settingsKey:(NSString*)setting {
    return [NSString stringWithFormat:@"IAP%@%@", self.identifier, setting];
}

- (NSString*)priceKey {
    return [self settingsKey:@"price"];
}

- (NSString*)stateKey {
    return [self settingsKey:@"state"];
}

- (void)save  {
    [self.settings setValue:self.price forKey:[self priceKey]];
    [self.settings setValue:self.state forKey:[self stateKey]];
}

- (void)restore {
    self.price = [self.settings valueForKey:[self priceKey]];
    NSString* stateSetting = [self.settings valueForKey:[self stateKey]];
    const NSString* state = kStateLoading;
    if ([kStatePurchased isEqualToString:stateSetting]) {
        state = kStatePurchased;
    }
    else if ([kStateRestored isEqualToString:stateSetting]) {
        state = kStateRestored;
    }
    [self loadStateMachine:state];
}

- (BOOL)identifierEquals:(NSString*)identifier {
    return identifier && [identifier isEqualToString:self.identifier];
}

- (BOOL)isLoading {
    return [self.stateMachine isInState:kStateLoading];
}

- (BOOL)isReadyForSale {
    return [self.stateMachine isInState:kStateReadyForSale];
}

- (BOOL)isError {
    return [self.stateMachine isInState:kStateError];
}

- (BOOL)isPurchasing {
    return [self.stateMachine isInState:kStatePurchasing];
}

- (BOOL)isPurchased {
    return [self.stateMachine isInState:kStatePurchased] || [self.stateMachine isInState:kStateRestored];
}

- (BOOL)isRestored {
    return [self.stateMachine isInState:kStateRestored];
}

- (void)purchase {
    [self.catalogue purchaseProduct:self];
}

- (void)addObserver:(id<IAPProductObserver>)iapProductObserver {
    [self.observers addObject:[NSValue valueWithNonretainedObject:iapProductObserver]];
    [self cleanEmptyObservers];
}

- (void)removeObserver:(id<IAPProductObserver>)iapProductObserver {
    [self.observers removeObject:[NSValue valueWithNonretainedObject:iapProductObserver]];
    [self cleanEmptyObservers];
}

- (void)notifyObserversOfStateChange {
    for (NSValue* observer in self.observers) {
        id<IAPProductObserver> iapProductObserver = [observer nonretainedObjectValue];
        if (!iapProductObserver)
            continue;
        
        if (self.isLoading && [iapProductObserver respondsToSelector:@selector(iapProductJustStartedLoading::)]) {
            [iapProductObserver iapProductJustStartedLoading:self];
        }
        else if (self.isError && [iapProductObserver respondsToSelector:@selector(iapProductJustErrored:)]) {
            [iapProductObserver iapProductJustErrored:self];
        }
        else if (self.isReadyForSale && [iapProductObserver respondsToSelector:@selector(iapProductJustBecameReadyForSale:)]) {
            [iapProductObserver iapProductJustBecameReadyForSale:self];
        }
        else if (self.isPurchased && [iapProductObserver respondsToSelector:@selector(iapProductWasJustPurchased:)]) {
            [iapProductObserver iapProductWasJustPurchased:self];
        }
        else if (self.isPurchasing && [iapProductObserver respondsToSelector:@selector(iapProductIsPurchasing:)]) {
            [iapProductObserver iapProductIsPurchasing:self];
        }
        else if (self.isRestored && [iapProductObserver respondsToSelector:@selector(iapProductWasJustRestored:)]) {
            [iapProductObserver iapProductWasJustRestored:self];
        }
    }
    
    [self cleanEmptyObservers];
}

- (void)cleanEmptyObservers {
    NSMutableArray* toDelete = [NSMutableArray array];
    
    for (NSValue* observer in self.observers) {
        if (![observer nonretainedObjectValue]) {
            [toDelete addObject:observer];
        }
    }
    
    [self.observers removeObjectsInArray:toDelete];
}

@end
