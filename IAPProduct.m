#import "IAPProduct.h"
#import <StoreKit/StoreKit.h>
#import "FSMMachine.h"

@interface IAPProduct()
@property (nonatomic, readwrite, strong) NSString* identifier;
@property (nonatomic, readwrite, strong) NSDecimalNumber* price;
@property (nonatomic, strong) FSMMachine* stateMachine;
@property (nonatomic, readwrite, strong) NSString* state;
- (void)loadStateMachine;
- (void)unloadStateMachine;
@end

@implementation IAPProduct
@synthesize identifier = _identifier;
@synthesize price = _price;
@synthesize stateMachine;
@synthesize state;

// State machine states and events 
static NSString* StateLoading = @"Loading";
static NSString* StateReadyForSale = @"ReadyForSale";
static NSString* StatePurchased = @"Purchased";
static NSString* EventSetPrice = @"SetPrice";

- (id)initWithIdentifier:(NSString*)identifier {
    self = [super init];
    
    if (self) {
        self.identifier = identifier;
        [self loadStateMachine];
    }
    
    return self;
}

- (void)dealloc {
    [self unloadStateMachine];
}

- (void)loadStateMachine { 
    self.stateMachine = [[FSMMachine alloc] initWithState:StateLoading];
    [self.stateMachine addTransition:EventSetPrice startState:StateLoading endState:StateReadyForSale];
    [self.stateMachine addTransition:EventSetPrice startState:StateReadyForSale endState:StateReadyForSale];
    [self.stateMachine addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
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
    [self.stateMachine applyEvent:EventSetPrice];
}

- (BOOL)identifierEquals:(NSString*)identifier {
    return identifier && [identifier isEqualToString:self.identifier];
}

- (BOOL)isLoading {
    return [self.stateMachine isInState:StateLoading];
}

- (BOOL)isReadyForSale {
    return [self.stateMachine isInState:StateReadyForSale];
}

- (BOOL)isPurchased {
    return [self.stateMachine isInState:StatePurchased];
}

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
