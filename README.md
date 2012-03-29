Purpose
--------------

InAppPurchasing is an easy wrapper around the StoreKit API that makes some of the more tedious aspects of In App Purchasing easier. It is written in Objective C for iPhone applications and uses Cedar for unit tests. 

Things InAppPurchasing does on top of StoreKit:

* Loads the prices of your in app purchases in the background.
* Updates the prices off your in app purchase in the background (in case they change).
* Provides a unified interface for fetching a purchase's details and price.
* Provides a unified interface for observing changes in a purchase's state.
* Remembers the prices of your purchases so you don't have to.
* Provides a singleton so you can access your purchase's from a single repository from within your application.

Usage
--------------

1. Add the InAppPurchasing submodule to your project by running the following command from the root directory of your project.

        git submodule add git@github.com:Bonobolabs/ios-in-app-purchasing.git External/InAppPurchasing

2. Add the InAppPurchasing folder to your project in XCode.

3. Customise the IAPInfo.plist file by adding your specific purchase identifiers from iTunes Connect.

4. Link to the StoreKit.framework in XCode.

5. Start the IAPStoreManager auto updating from your AppDelegate file. This will start the background process of fetching and updating the details and prices of your in app purchases. If it encounters an error it will periodically keep retrying to fetch the purchase's details.

        #import "IAPStoreManager.h"

        - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
        {
            // Override point for customization after application launch.
	        [[IAPStoreManager sharedInstance] autoUpdate];
	        return YES;
	    }
	
6. Purchase an in app purchase.

        - (void)buyButtonTapped:(id)sender {
			IAPProduct* product = [[IAPStoreManager sharedInstance] productForIdentifier:@"com.bonobolabs.SingleBanana"];
			[product purchase];
        }

7. Monitor the state of an in app purchase by implementing the IAPProductObserver protocol.

        @interface ProductTableViewCell : UITableViewCell<IAPProductObserver>

        // Start observing the product.
        - (void)initProduct:(NSString*)productIdentifier {
          self.product = [[IAPStoreManager sharedInstance] productForIdentifier:@"com.bonobolabs.SingleBanana"];
          [self.product addObserver:self];
        }

        // If an error is encountered.
        - (void)iapProductJustErrored:(IAPProduct*)iapProduct {
          [self setButtonState]; 
        }

        // If we're requesting the In App Purchase's details from Apple.
        - (void)iapProductJustStartedLoading:(IAPProduct*)iapProduct {
          [self setButtonState];    
        }

        // If we've received the In App Purchase's details from Apple.
        - (void)iapProductJustBecameReadyForSale:(IAPProduct*)iapProduct {
          [self setButtonState];
        }

        // If a purchase was successfully made.
        - (void)iapProductWasJustPurchased:(IAPProduct*)iapProduct {
          [self setButtonState];
        }

        // If a purchase was successfully restored.
        - (void)iapProductWasJustRestored:(IAPProduct*)iapProduct {
          [self setButtonState];
        }

        // If a purchase was initiated.
        - (void)iapProductIsPurchasing:(IAPProduct*)iapProduct {
          [self setButtonState];
        }

        // Just a snippet that shows the purchase state in use.
        - (void)setButtonState {
          BOOL enabled = NO;
          NSString* title = @"";
    
          if (self.product.isLoading) {
            title = @"Loading...";
          }
          else if (self.product.isPurchasing) {
            title = @"Purchasing...";
          }
          else if (self.product.isError) {
            title = @"Error";
          }
          else if (self.product.isPurchased) {
            title = @"Purchased";
          }
          else if (self.product.isReadyForSale) {
            title = self.product.price;
            enabled = YES;
          }
 
          [self.actionButton setEnabled:enabled];
          [self.actionButton setTitle:title forState:UIControlStateNormal];
        }

8. Remember to remove the observer when you're done with it:

        - (void)dealloc {
          [self.product removeObserver:self];
        }

Tests & Sample Project
--------------

InAppPurchasing has been separated out into its own repository to make it easy to add to your project as a submodule. If you'd like to view the sample project and run the tests they are available at https://github.com/Bonobolabs/ios-in-app-purchasing-framework
