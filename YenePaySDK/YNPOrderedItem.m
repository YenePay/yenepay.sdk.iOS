//
//  YNPOrderedItem.m
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import "YNPOrderedItem.h"

@implementation YNPOrderedItem

- (double)totalPrice {
    return self.quantity * self.unitPrice;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    YNPOrderedItem *clone = [[YNPOrderedItem alloc] init];
    clone.itemId = self.itemId;
    clone.itemName = self.itemName;
    clone.unitPrice = self.unitPrice;
    clone.quantity = self.quantity;
    return clone;
}

@end
