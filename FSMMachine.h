@class FSMState;

@interface FSMMachine : NSObject
@property (nonatomic, readonly, strong) const NSString* state;
- (id)initWithState:(const NSString*)state;
- (void)addTransition:(const NSString*)event startState:(const NSString*)startState endState:(const NSString*)endState;
- (BOOL)applyEvent:(const NSString*)event;
- (BOOL)isInState:(const NSString*)state;
@end
