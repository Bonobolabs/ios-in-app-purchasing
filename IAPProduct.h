#import <Foundation/Foundation.h>

@protocol IAPProductObserver;

@interface IAPProduct : NSObject
@property (nonatomic, readonly, strong) NSString* identifier;
@property (nonatomic, readonly, strong) NSString* price;
@property (nonatomic, readonly, assign) BOOL isLoading;
@property (nonatomic, readonly, assign) BOOL isReadyForSale;
@property (nonatomic, readonly, assign) BOOL isPurchased;
@property (nonatomic, readonly, assign) BOOL isError;
@property (nonatomic, readonly, assign) BOOL isPurchasing;
@property (nonatomic, readonly, assign) BOOL isRestored;
@property (nonatomic, readonly, assign) BOOL isRestoring;

- (void)addObserver:(id<IAPProductObserver>)iapProductObserver;
- (void)removeObserver:(id<IAPProductObserver>)iapProductObserver;
- (void)purchase;
- (void)restorePurchase;

@end

@protocol IAPProductObserver <NSObject>
@optional
- (void)iapProductWasUpdated:(IAPProduct*)iapProduct;
@end