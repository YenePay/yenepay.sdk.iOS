//
//  YNPPaymentOrder.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <Foundation/Foundation.h>

#import <YenePaySDK/YNPOrderedItem.h>

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSInteger {
    YNPPaymentProcessTypeCart = 1,
    YNPPaymentProcessTypeExpress
} YNPPaymentProcessType;

@class PaymentOrderValidationResult, YNPOrderedItem;


@interface YNPPaymentOrder : NSObject <NSCopying>

@property (nonatomic, copy, nullable) NSString *merchantOrderId;
@property (nonatomic) YNPPaymentProcessType paymentProcess;     // default is YNPPaymentProcessTypeExpress
@property (nonatomic, /*deep*/ copy) NSArray<YNPOrderedItem *> *items;
@property (nonatomic) double discount;      // default is 0.0
@property (nonatomic) double tax1;          // default is 0.0
@property (nonatomic) double tax2;          // default is 0.0
@property (nonatomic) double handlingFee;   // default is 0.0
@property (nonatomic) double deliveryFee;   // default is 0.0

@property (nonatomic, readonly) double itemsTotal;      // computed

@end

NS_ASSUME_NONNULL_END
