//
//  YNPPaymentResponse.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    YNPPaymentStatusNew = 1,
    YNPPaymentStatusProcessing = 2,
    YNPPaymentStatusCanceled = 3,
    YNPPaymentStatusError = 4,
    YNPPaymentStatusCompleted = 5,
    YNPPaymentStatusDisputed = 6,
    YNPPaymentStatusUnkown = 7,
    YNPPaymentStatusWaiting = 8,
    YNPPaymentStatusPaid = 9,
    YNPPaymentStatusDelivered = 10,
    YNPPaymentStatusVerifying = 11,
    YNPPaymentStatusExpired = 12
} YNPPaymentStatus;



@interface YNPPaymentResponse : NSObject

@property (nonatomic, readonly, copy) NSString *paymentOrderId;
@property (nonatomic, readonly, copy) NSString *orderCode;
@property (nonatomic, readonly, copy) NSString *buyerId;
@property (nonatomic, readonly, copy) NSString *merchantId;
@property (nonatomic, readonly, copy) NSString *merchantOrderId;
@property (nonatomic, readonly) double grandTotal;
@property (nonatomic, readonly) YNPPaymentStatus status;
@property (nonatomic, readonly, copy) NSString *statusText;
@property (nonatomic, readonly, copy) NSString *signature;

@property (nonatomic, readonly) BOOL isPending;
@property (nonatomic, readonly) BOOL isPaymentCompleted;

@end


NS_ASSUME_NONNULL_END
