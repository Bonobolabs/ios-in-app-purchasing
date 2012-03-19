#import "IAPProduct.h"
#import <StoreKit/StoreKit.h>
#import "FSMMachine.h"
#import "IAPCatalogue.h"

@interface IAPProduct()
@property (nonatomic, readwrite, strong) NSString* identifier;
@property (nonatomic, strong) IAPCatalogue* catalogue;
@property (nonatomic, readwrite, strong) NSDecimalNumber* price;
@property (nonatomic, strong) FSMMachine* stateMachine;
@property (nonatomic, readwrite, strong) const NSString* state;
- (void)loadStateMachine;
- (void)unloadStateMachine;
@end

@implementation IAPProduct
@synthesize identifier = _identifier;
@synthesize catalogue = _catalogue;
@synthesize price = _price;
@synthesize stateMachine;
@synthesize state;

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

- (id)initWithCatalogue:(IAPCatalogue*)catalogue identifier:(NSString*)identifier {
    self = [super init];
    
    if (self) {
        self.identifier = identifier;
        self.catalogue = catalogue;
        [self loadStateMachine];
    }
    
    return self;
}

- (void)dealloc {
    [self unloadStateMachine];
}

- (void)loadStateMachine { 
    self.stateMachine = [[FSMMachine alloc] initWithState:kStateLoading];
    [self.stateMachine addTransition:kEventSetPrice startState:kStateLoading endState:kStateReadyForSale];
    [self.stateMachine addTransition:kEventSetPrice startState:kStateReadyForSale endState:kStateReadyForSale];
    [self.stateMachine addTransition:kEventSetError startState:kStateLoading endState:kStateError];
    [self.stateMachine addTransition:kEventSetError startState:kStatePurchasing endState:kStateError];
    [self.stateMachine addTransition:kEventRecoverToReadyForSale startState:kStateError endState:kStateReadyForSale];
    [self.stateMachine addTransition:kEventRecoverToLoading startState:kStateError endState:kStateLoading];
    [self.stateMachine addTransition:kEventSetPurchasing startState:kStateReadyForSale endState:kStatePurchasing];
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
            self.state = self.stateMachine.state;
        }
    }
}

- (void)updateWithSKProduct:(SKProduct*)skProduct {
    self.price = skProduct.price;
    [self.stateMachine applyEvent:kEventSetPrice];
}

- (void)updateWithSKPaymentTransaction:(SKPaymentTransaction*)skTransaction {
    switch (skTransaction.transactionState) {
        case SKPaymentTransactionStatePurchased: {
            [self.stateMachine applyEvent:kEventSetPurchased];
            break;
        }
        case SKPaymentTransactionStateFailed: {
            const NSString* recoverEvent = kEventRecoverToLoading;
            if (self.state == kStatePurchasing) {
                recoverEvent = kEventRecoverToReadyForSale;
            }
            [self.stateMachine applyEvent:kEventSetError];
            [self.stateMachine applyEvent:recoverEvent];
            break;
        }
        case SKPaymentTransactionStateRestored: {
            [self.stateMachine applyEvent:kEventSetRestored];
            break;
        }
    }
}

- (void)updateWithSKPayment:(SKPayment*)skPayment {
    [self.stateMachine applyEvent:kEventSetPurchasing];
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
    return [self.stateMachine isInState:kStatePurchased];
}

- (BOOL)isRestored {
    return [self.stateMachine isInState:kStateRestored];
}

- (void)purchase {
    [self.catalogue purchaseProduct:self];
}

// loading => error => loading
// ready for sale => purchasing => error => loaded
// ready for sale => purchasing => purchased
// ready for sale => purchasing => restored

// ready for sale => set price => ready for sale
//loading => set price => ready for sale
//loading => received error => error
//error => loading
//loaded => purchasing
//loaded => restoring
//purchasing => purchased
//purchasing => purchasing failed
//purchasing failed => purchasing
//restoring => restored

@end
