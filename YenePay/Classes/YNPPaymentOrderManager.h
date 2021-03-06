//
//  YNPPaymentOrderManager.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <Foundation/Foundation.h>

#import "YNPPaymentOrder.h"
#import "YNPPaymentResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YNPPaymentOrderManagerDelegate;

@interface YNPPaymentOrderManager : NSObject

@property (nonatomic) BOOL useSandboxEnabled;       // default is NO
@property (nonatomic, copy, nullable) NSString *merchantCode;
@property (nonatomic, copy, nullable) NSString *ipnUrl;
@property (nonatomic, copy, nullable) NSString *returnUrl;

@property (nonatomic, weak, nullable) id<YNPPaymentOrderManagerDelegate> delegate;

+ (instancetype)sharedInstance;

- (BOOL)handleOpenUrl:(NSURL *)url;

- (void)checkoutWithPaymentOrder:(YNPPaymentOrder *)paymentOrder
        paymentCompletionHandler:(void(^)(YNPPaymentResponse *__nullable response, NSError *__nullable error))completionHandler;

@end


@protocol YNPPaymentOrderManagerDelegate <NSObject>

@optional
- (void)paymentOrderManager:(YNPPaymentOrderManager *)paymentManager
  didReceivePaymentResponse:(YNPPaymentResponse *)paymentResponse;

@end


FOUNDATION_EXTERN NSNotificationName const YNPPaymentCompletedNotification;
FOUNDATION_EXTERN NSString *const YNPPaymentResponseUserInfoKey;

NS_ASSUME_NONNULL_END
