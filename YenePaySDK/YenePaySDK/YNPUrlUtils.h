//
//  YNPUrlUtils.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <Foundation/Foundation.h>

#import <YenePaySDK/YNPPaymentOrder.h>
#import <YenePaySDK/YNPPaymentResponse.h>

NS_ASSUME_NONNULL_BEGIN

@interface YNPUrlUtils : NSObject

/// <#Description#>
/// @param paymentOrder <#paymentOrder description#>
/// @param endpoint The endpoint address including the url scheme (eg. "https://www.yenepay.com/checkout/Home/Process")
+ (NSURL *__nullable)checkoutUrlForPaymentOrder:(YNPPaymentOrder *)paymentOrder
                                       endpoint:(NSString *)endpoint;

+ (YNPPaymentResponse *__nullable)parsePaymentResponseUrl:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
