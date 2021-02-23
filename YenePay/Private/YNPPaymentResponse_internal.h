//
//  YNPPaymentResponse_internal.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/20/21.
//

#ifndef YNPPaymentResponse_internal_h
#define YNPPaymentResponse_internal_h

#import "YNPPaymentResponse.h"

NS_ASSUME_NONNULL_BEGIN

static YNPPaymentStatus const YNPMinPaymentStatus = YNPPaymentStatusNew;
static YNPPaymentStatus const YNPMaxPaymentStatus = YNPPaymentStatusExpired;


@interface YNPPaymentResponse ()

@property (nonatomic, readwrite, copy) NSString *paymentOrderId;
@property (nonatomic, readwrite, copy) NSString *orderCode;
@property (nonatomic, readwrite, copy) NSString *buyerId;
@property (nonatomic, readwrite, copy) NSString *merchantId;
@property (nonatomic, readwrite, copy) NSString *merchantOrderId;
@property (nonatomic, readwrite) double grandTotal;
@property (nonatomic, readwrite) YNPPaymentStatus status;
@property (nonatomic, readwrite, copy) NSString *statusText;
@property (nonatomic, readwrite, copy) NSString *signature;

@property (nonatomic, readonly) NSString *verificationString;

- (void)setStatusAndStatusTextFromString:(NSString *__nullable)statusText;

@end

NS_ASSUME_NONNULL_END

#endif /* YNPPaymentResponse_internal_h */
