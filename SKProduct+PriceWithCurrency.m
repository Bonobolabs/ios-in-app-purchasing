#import "SKProduct+PriceWithCurrency.h"

@implementation SKProduct (PriceWithCurrency)

- (NSString *)priceWithCurrency
{
    if (!self.priceLocale || !self.price) {
        return nil;
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[self priceLocale]];
    
    NSString *str = [formatter stringFromNumber:[self price]];
    return str;
}

@end