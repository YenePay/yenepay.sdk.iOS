//
//  YNPUrlUtils.m
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import "YNPUrlUtils.h"

#import "YNPPaymentOrder_internal.h"
#import "YNPPaymentResponse_internal.h"

static NSString * const kUrlParamKeyMerchantId = @"MerchantId";
static NSString * const kUrlParamKeyMerchantOrderId = @"MerchantOrderId";
static NSString * const kUrlParamKeyProcess = @"Process";
static NSString * const kUrlParamProcessValueCart = @"Cart";
static NSString * const kUrlParamProcessValueExpress = @"Express";
static NSString * const kUrlParamKeyItemId = @"ItemId";
static NSString * const kUrlParamKeyItemName = @"ItemName";
static NSString * const kUrlParamKeyUnitPrice = @"UnitPrice";
static NSString * const kUrlParamKeyQuantity = @"Quantity";
static NSString * const kUrlParamKeyTax1 = @"Tax1";
static NSString * const kUrlParamKeyTax2 = @"Tax2";
static NSString * const kUrlParamKeyItems = @"Items";
static NSString * const kUrlParamKeyDiscount = @"Discount";
static NSString * const kUrlParamKeyHandlingFee = @"HandlingFee";
static NSString * const kUrlParamKeyShippingFee = @"DeliveryFee";
static NSString * const kUrlParamKeyCancelUrl = @"CancelUrl";
static NSString * const kUrlParamKeySuccessUrl = @"SuccessUrl";
static NSString * const kUrlParamKeyFailureUrl = @"FailureUrl";
static NSString * const kUrlParamKeyIpnUrl = @"IpnUrl";
static NSString * const kUrlParamKeyBuyerId = @"BuyerId";
static NSString * const kUrlParamKeySignature = @"Signature";
static NSString * const kUrlParamKeyStatus = @"Status";
static NSString * const kUrlParamKeyTransactionId = @"TransactionId";
static NSString * const kUrlParamKeyTransactionCode = @"TransactionCode";
static NSString * const kUrlParamKeyTotalAmount = @"TotalAmount";
static NSString * const kUrlParamKeyErrorMsg = @"ErrorMsg";


@implementation YNPUrlUtils

+ (NSURL *__nullable)checkoutUrlForPaymentOrder:(YNPPaymentOrder *)paymentOrder
                                       endpoint:(NSString *)endpoint {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:endpoint];
    if (urlComponents == nil) return nil;
    
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray array];
    void(^addQueryKeyValue)(NSString*, NSString*) = ^(NSString *key, NSString *value) {
        if (value.length > 0) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        }
    };
    
    NSString* (^formatAmount)(double) = ^ NSString* (double amount) {
        return [NSString stringWithFormat:@"%.3f", amount];
    };
    
    NSString* (^formatQuantity)(NSInteger) = ^ NSString* (NSInteger quantity) {
        return [NSString stringWithFormat:@"%ld", (long)(long)quantity];
    };
    
    
    addQueryKeyValue(kUrlParamKeyMerchantId, paymentOrder.merchantCode);
    addQueryKeyValue(kUrlParamKeyIpnUrl, paymentOrder.ipnUrl);
    addQueryKeyValue(kUrlParamKeySuccessUrl, paymentOrder.returnUrl);
    addQueryKeyValue(kUrlParamKeyCancelUrl, paymentOrder.returnUrl);
    addQueryKeyValue(kUrlParamKeyFailureUrl, paymentOrder.returnUrl);
    
    addQueryKeyValue(kUrlParamKeyMerchantOrderId, paymentOrder.merchantOrderId);
    if (paymentOrder.paymentProcess == YNPPaymentProcessTypeCart) {
        addQueryKeyValue(kUrlParamKeyProcess, kUrlParamProcessValueCart);
    } else {
        addQueryKeyValue(kUrlParamKeyProcess, kUrlParamProcessValueExpress);
    }

    if (paymentOrder.isExpress) {
        addQueryKeyValue(kUrlParamKeyDiscount, formatAmount(paymentOrder.discount));
        addQueryKeyValue(kUrlParamKeyTax1, formatAmount(paymentOrder.tax1));
        addQueryKeyValue(kUrlParamKeyTax2, formatAmount(paymentOrder.tax2));
        addQueryKeyValue(kUrlParamKeyHandlingFee, formatAmount(paymentOrder.handlingFee));
        addQueryKeyValue(kUrlParamKeyShippingFee, formatAmount(paymentOrder.deliveryFee));

        YNPOrderedItem *item = paymentOrder.items.firstObject;
        addQueryKeyValue(kUrlParamKeyItemId, item.itemId);
        addQueryKeyValue(kUrlParamKeyItemName, item.itemName);
        addQueryKeyValue(kUrlParamKeyQuantity, formatQuantity(item.quantity));
        addQueryKeyValue(kUrlParamKeyUnitPrice, formatAmount(item.unitPrice));
    } else {
        addQueryKeyValue([@"TotalItems" stringByAppendingString:kUrlParamKeyDiscount], formatAmount(paymentOrder.discount));
        addQueryKeyValue([@"TotalItems" stringByAppendingString:kUrlParamKeyTax1], formatAmount(paymentOrder.tax1));
        addQueryKeyValue([@"TotalItems" stringByAppendingString:kUrlParamKeyTax2], formatAmount(paymentOrder.tax2));
        addQueryKeyValue([@"TotalItems" stringByAppendingString:kUrlParamKeyHandlingFee], formatAmount(paymentOrder.handlingFee));
        addQueryKeyValue([@"TotalItems" stringByAppendingString:kUrlParamKeyShippingFee], formatAmount(paymentOrder.deliveryFee));

        for (int index = 0; index < paymentOrder.items.count; index++) {
            NSString* (^indexedKey)(NSString*) = ^ NSString* (NSString *key) {
                return [NSString stringWithFormat:@"Items[%d].%@", index, key];
            };
            
            YNPOrderedItem *item = paymentOrder.items[index];
            addQueryKeyValue(indexedKey(kUrlParamKeyItemId), item.itemId);
            addQueryKeyValue(indexedKey(kUrlParamKeyItemName), item.itemName);
            addQueryKeyValue(indexedKey(kUrlParamKeyQuantity), formatQuantity(item.quantity));
            addQueryKeyValue(indexedKey(kUrlParamKeyUnitPrice), formatAmount(item.unitPrice));
        }
    }
    
    urlComponents.queryItems = queryItems;
    return urlComponents.URL;
}


+ (YNPPaymentResponse *__nullable)parsePaymentResponseUrl:(NSURL *)url {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    if (urlComponents == nil) return nil;
        
    NSMutableDictionary<NSString*, NSString*> *queryKeyValues = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
        if (queryItem.value) queryKeyValues[queryItem.name] = queryItem.value;
    }
    
    YNPPaymentResponse *response = [[YNPPaymentResponse alloc] init];
    response.buyerId = queryKeyValues[kUrlParamKeyBuyerId];
    response.signature = queryKeyValues[kUrlParamKeySignature];
    response.merchantId = queryKeyValues[kUrlParamKeyMerchantId];
    response.merchantOrderId = queryKeyValues[kUrlParamKeyMerchantOrderId];
    [response setStatusAndStatusTextFromString:queryKeyValues[kUrlParamKeyStatus]];
    response.paymentOrderId = queryKeyValues[kUrlParamKeyTransactionId];
    response.orderCode = queryKeyValues[kUrlParamKeyTransactionCode];
    response.grandTotal = [queryKeyValues[kUrlParamKeyTotalAmount] stringByReplacingOccurrencesOfString:@"," withString:@""].doubleValue;
    
    return response;
}

@end
