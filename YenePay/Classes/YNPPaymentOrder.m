//
//  YNPPaymentOrder.m
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import "YNPPaymentOrder.h"
#import "YNPPaymentOrder_internal.h"

@implementation YNPPaymentOrder

- (instancetype)init {
    return [self initWithMerchantOrderId:NSUUID.UUID.UUIDString];
}

- (instancetype)initWithMerchantOrderId:(NSString *)merchantOrderId {
    self = [super init];
    if (self) {
        _merchantOrderId = [merchantOrderId copy];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    YNPPaymentOrder *clone = [[YNPPaymentOrder alloc] init];
    clone.merchantOrderId = self.merchantOrderId;
    clone.paymentProcess = self.paymentProcess;
    clone.items = self.items;
    clone.discount = self.discount;
    clone.tax1 = self.tax1;
    clone.tax2 = self.tax2;
    clone.handlingFee = self.handlingFee;
    clone.deliveryFee = self.deliveryFee;
    
    clone.merchantCode = self.merchantCode;
    clone.ipnUrl = self.ipnUrl;
    clone.returnUrl = self.returnUrl;
    
    return clone;
}


- (void)setItems:(NSArray<YNPOrderedItem *> *)items {
    _items = items ? [[NSArray alloc] initWithArray:items copyItems:YES] : nil;    // deep copy
}

- (double)itemsTotal {
    double total = 0;
    for (YNPOrderedItem *item in _items) {
        total += item.totalPrice;
    }
    return total;
}

- (BOOL)isExpress {
    return (self.paymentProcess == YNPPaymentProcessTypeExpress) && (self.items.count == 1);
}

@end
