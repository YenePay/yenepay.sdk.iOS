//
//  YNPPaymentOrder_internal.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/20/21.
//

#ifndef YNPPaymentOrder_internal_h
#define YNPPaymentOrder_internal_h

#import "YNPPaymentOrder.h"

@interface YNPPaymentOrder()

// additional values that we need to generate checkout urls
@property (nonatomic, copy, nullable) NSString *merchantCode;
@property (nonatomic, copy, nullable) NSString *ipnUrl;
@property (nonatomic, copy, nullable) NSString *returnUrl;

@property (nonatomic, readonly) BOOL isExpress;     // computed

@end

#endif /* YNPPaymentOrder_internal_h */
