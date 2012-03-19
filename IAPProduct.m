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
@synthesize state = _state;

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
        [self loadStateMachine: kStateLoading];
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
            self.state = self.stateMachine.state;
        }
    }
}

- (void)updateWithSKProduct:(SKProduct*)skProduct {
    self.price = skProduct.price;
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

- (void)save {
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    [settings setValue:self.price forKey:[self settingsKey:@"price"]];
    [settings setValue:self.state forKey:[self settingsKey:@"state"]];
}

- (void)restore {
    NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
    
    self.price = [settings valueForKey:[self settingsKey:@"price"]];
    NSString* stateSetting = [settings valueForKey:[self settingsKey:@"state"]];
    const NSString* state = kStateLoading;
    if ([kStatePurchased isEqualToString:stateSetting]) {
        state = kStatePurchased;
    }
    else if ([kStateRestored isEqualToString:stateSetting]) {
        state = kStateRestored;
    }
    [self loadStateMachine:state];
}

- (const NSString*) stateForPrice:(NSDecimalNumber*)price purchased:(BOOL)purchased {
    const NSString* state = kStateLoading;
    if (price != nil) {
        state = kStateReadyForSale;
    }
    if (purchased) {
        state = kStatePurchased;
    }
    return state;
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

@end
