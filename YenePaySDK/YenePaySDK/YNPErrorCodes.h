//
//  YNPErrorCodes.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__BEGIN_DECLS

extern NSErrorDomain const YNPPaymentErrorDomain;

__END_DECLS


typedef NS_ERROR_ENUM(YNPPaymentErrorDomain, YNPPaymentError) {
    YNPPaymentErrorUnknown = 0,
    YNPPaymentErrorInvalidState = 1,
    YNPPaymentErrorInvalidArgument = 2,
    YNPPaymentErrorUserCancelledPayment = 3,
};

NS_ASSUME_NONNULL_END
