//
//  YNPPaymentOrderManager.m
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <UIKit/UIApplication.h>

#import "YNPPaymentOrderManager.h"

#import "YNPErrorCodes.h"
#import "YNPPaymentOrder_internal.h"
#import "YNPPaymentResponse_internal.h"
#import "YNPUrlUtils.h"


NSNotificationName const YNPPaymentCompletedNotification = @"YNPPaymentCompletedNotification";
NSString *const YNPPaymentResponseUserInfoKey = @"YNPPaymentResponse";


@interface PaymentOrderValidationResult : NSObject

@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly, nullable) NSArray<NSString *> *errorMessages;

@property (nonatomic, readonly) NSError *error;

@end

@interface PaymentOrderValidationResult()

+ (PaymentOrderValidationResult *)validResult;
+ (PaymentOrderValidationResult *)resultWithErrorMessages:(NSArray<NSString *> *)errorMessages;

@end



typedef void(^YNPPaymentCompletionHandler_t)(YNPPaymentResponse *__nullable response, NSError *__nullable error);



@interface YNPPaymentOrderInfo : NSObject

@property (nonatomic, strong, readonly) YNPPaymentOrder *paymentOrder;
@property (nonatomic, strong, readonly) YNPPaymentCompletionHandler_t completionHandler;

@end

@implementation YNPPaymentOrderInfo

- (instancetype)initWithPayment:(YNPPaymentOrder *)paymentOrder handler:(YNPPaymentCompletionHandler_t)handler {
    self = [super init];
    if (self) {
        _paymentOrder = paymentOrder;
        _completionHandler = handler;
    }
    return self;
}

@end



@interface YNPPaymentOrderManager()

@property (nonatomic, readonly, nonnull) NSString *checkoutEndpoint;
@property (nonatomic, readonly, nonnull) NSMutableDictionary<NSString*, YNPPaymentOrderInfo*> *paymentInfos;

- (BOOL)isCheckoutInProgressForOrderId:(NSString *)orderId;

@end


@implementation YNPPaymentOrderManager

+ (instancetype)sharedInstance {
    static YNPPaymentOrderManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[YNPPaymentOrderManager alloc] init];
    });
    return sharedInstance;
}

- (BOOL)handleOpenUrl:(NSURL *)url {
    if (![self canHandleUrl:url.absoluteString]) return NO;
    
    YNPPaymentResponse *response = [YNPUrlUtils parsePaymentResponseUrl:url];
    if (response == nil) {
        NSLog(@"[YNPPaymentOrderManager] ** Failed to parse response url: %@", url.absoluteString);
        return NO;
    }
    
// TODO: verify response before going any further
    
    if (response.merchantOrderId && [self isCheckoutInProgressForOrderId:response.merchantOrderId]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishCheckoutWithOrderId:response.merchantOrderId response:response error:nil];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(paymentOrderManager:didReceivePaymentResponse:)]) {
            [self.delegate paymentOrderManager:self didReceivePaymentResponse:response];
        }
        
        if (response.isPaymentCompleted) {
            [self postPaymentCompletedNotificationWithResponse:response];
        }
    });
    
    return YES;
}

- (void)checkoutWithPaymentOrder:(YNPPaymentOrder *)paymentOrder
        paymentCompletionHandler:(void(^)(YNPPaymentResponse *response, NSError *error))completionHandler {
    
    if ([self isCheckoutInProgressForOrderId:paymentOrder.merchantOrderId]) {
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorDesc = NSLocalizedString(@"A previous checkout flow is still in progress.", nil);
                NSString *errorDebugDesc = @"A previous checkout flow with the same merchantOrderId is still in progress.";
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey : errorDesc,
                    NSDebugDescriptionErrorKey: errorDebugDesc
                };
                completionHandler(nil, [NSError errorWithDomain:YNPPaymentErrorDomain
                                                           code:YNPPaymentErrorInvalidState
                                                       userInfo:userInfo]);
            });
        }
        return;
    } // else...
    
    YNPPaymentOrder *payment = [paymentOrder copy];
    payment.merchantCode = self.merchantCode;
    payment.ipnUrl = self.ipnUrl;
    payment.returnUrl = self.returnUrl;
    self.paymentInfos[payment.merchantOrderId] = [[YNPPaymentOrderInfo alloc] initWithPayment:payment handler:completionHandler];
    
    PaymentOrderValidationResult *validationResult = [YNPPaymentOrderManager validatePaymentOrder:payment];
    if (!validationResult.isValid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishCheckoutWithOrderId:payment.merchantOrderId response:nil error:validationResult.error];
        });
        return;
    } // else...
        
    NSURL *checkoutUrl = [YNPUrlUtils checkoutUrlForPaymentOrder:payment endpoint:self.checkoutEndpoint];
#if DEBUG
    NSLog(@"[YNPPaymentOrderManager] Checkout Url (len = %d) = %@", (int)checkoutUrl.absoluteString.length, checkoutUrl);
#endif
    
    if (checkoutUrl == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorDesc = NSLocalizedString(@"Unable to complete payment.", nil);
            NSString *errorDebugDesc = @"Failed to generate checkout URL";
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey : errorDesc,
                NSDebugDescriptionErrorKey: errorDebugDesc
            };
            NSError *error = [NSError errorWithDomain:YNPPaymentErrorDomain
                                                 code:YNPPaymentErrorUnknown
                                             userInfo:userInfo];
            [self finishCheckoutWithOrderId:payment.merchantOrderId response:nil error:error];
        });
        return;
    } // else...
    
    // open the url
    [UIApplication.sharedApplication openURL:checkoutUrl options:@{} completionHandler:^(BOOL success) {
        if (!success) {
            NSString *errorDesc = NSLocalizedString(@"Unable to complete payment.", nil);
            NSString *errorDebugDesc = @"Failed open checkout URL";
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey : errorDesc,
                NSDebugDescriptionErrorKey: errorDebugDesc
            };
            NSError *error = [NSError errorWithDomain:YNPPaymentErrorDomain
                                                 code:YNPPaymentErrorUnknown
                                             userInfo:userInfo];
            [self finishCheckoutWithOrderId:payment.merchantOrderId response:nil error:error];
            return;
        }
    }];
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _paymentInfos = [NSMutableDictionary dictionary];
    }
    return self;
}


- (NSString *)checkoutEndpoint {
    if (self.useSandboxEnabled) {
        return @"https://test.yenepay.com/Home/Process";
    } else {
        return @"https://www.yenepay.com/checkout/Home/Process";
    }
}


- (BOOL)isCheckoutInProgressForOrderId:(NSString *)orderId {
    return self.paymentInfos[orderId] != nil;
}

- (BOOL)canHandleUrl:(NSString *)url {
    return self.returnUrl && [YNPPaymentOrderManager url:url matchesReturnUrl:self.returnUrl];
}

- (void)finishCheckoutWithOrderId:(NSString *)orderId response:(YNPPaymentResponse *)response error:(NSError *)error {
    YNPPaymentOrderInfo *info = self.paymentInfos[orderId];
    [self.paymentInfos removeObjectForKey:orderId];
    
    if (info.completionHandler) info.completionHandler(response, error);
}

- (void)postPaymentCompletedNotificationWithResponse:(YNPPaymentResponse *)response {
    NSDictionary *userInfo = @{YNPPaymentResponseUserInfoKey: response};
    [NSNotificationCenter.defaultCenter postNotificationName:YNPPaymentCompletedNotification
                                                      object:self
                                                    userInfo:userInfo];
}


+ (PaymentOrderValidationResult *)validatePaymentOrder:(YNPPaymentOrder *)paymentOrder {
    NSMutableArray<NSString *> *errorMessages = [NSMutableArray array];
    
    if (paymentOrder.merchantCode.length == 0) [errorMessages addObject:@"Merchant code must not be empty"];
    if (paymentOrder.returnUrl.length == 0) [errorMessages addObject:@"returnUrl must not be empty"];
    
    if (paymentOrder.tax1 < 0.0) [errorMessages addObject:@"tax1 value must be non-negative"];
    if (paymentOrder.tax2 < 0.0) [errorMessages addObject:@"tax2 value must be non-negative"];
    if (paymentOrder.discount < 0.0) [errorMessages addObject:@"discount value must be non-negative"];
    if (paymentOrder.handlingFee < 0.0) [errorMessages addObject:@"handlingFee value must be non-negative"];
    if (paymentOrder.deliveryFee < 0.0) [errorMessages addObject:@"deliveryFee value must be non-negative"];
    
    if (paymentOrder.items.count == 0) [errorMessages addObject:@"items must not be empty"];
    for (YNPOrderedItem *item in paymentOrder.items) {
        PaymentOrderValidationResult *itemResult = [YNPPaymentOrderManager validateItem:item];
        if (itemResult.errorMessages.count > 0) {
            [errorMessages addObjectsFromArray:itemResult.errorMessages];
        }
    }
    
    if (errorMessages.count > 0) {
        return [PaymentOrderValidationResult resultWithErrorMessages:errorMessages];
    } else {
        return [PaymentOrderValidationResult validResult];
    }
}

+ (PaymentOrderValidationResult *)validateItem:(YNPOrderedItem *)item {
    if (item == nil) {
        return [PaymentOrderValidationResult resultWithErrorMessages:@[@"Item must not be nil"]];
    } // else...
    
    NSMutableArray<NSString *> *errorMessages = [NSMutableArray array];
    
    if (item.itemName.length == 0) {
        [errorMessages addObject:@"Item name must not be empty"];
    }
    
    if (item.unitPrice <= 0) {
        [errorMessages addObject:@"Item unit price must be greater than 0"];
    }
    
    if (item.quantity <= 0) {
        [errorMessages addObject:@"Item quantity must be greater than 0"];
    }
    
    if (errorMessages.count > 0) {
        return [PaymentOrderValidationResult resultWithErrorMessages:errorMessages];
    } else {
        return [PaymentOrderValidationResult validResult];
    }
}

+ (BOOL)url:(NSString *)url matchesReturnUrl:(NSString *)returnUrl {
    return [url.lowercaseString hasPrefix:returnUrl.lowercaseString];
}

@end




@implementation PaymentOrderValidationResult

+ (PaymentOrderValidationResult *)validResult {
    PaymentOrderValidationResult *instance = [PaymentOrderValidationResult new];
    if (instance) {
        instance->_isValid = YES;
    }
    return instance;
}

+ (PaymentOrderValidationResult *)resultWithErrorMessages:(NSArray<NSString *> *)errorMessages {
    PaymentOrderValidationResult *instance = [PaymentOrderValidationResult new];
    if (instance) {
        instance->_isValid = NO;
        instance->_errorMessages = [errorMessages copy];
    }
    return instance;
}


- (NSError *)error {
    if (self.isValid) return nil;
    
    NSString *errorDesc = self.errorMessages.firstObject;
    NSString *errorDebugDesc = [self.errorMessages componentsJoinedByString:@", "];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (errorDesc) userInfo[NSLocalizedDescriptionKey] = errorDesc;
    if (errorDebugDesc) userInfo[NSDebugDescriptionErrorKey] = errorDebugDesc;
    return [NSError errorWithDomain:YNPPaymentErrorDomain
                               code:YNPPaymentErrorInvalidArgument
                           userInfo:userInfo];
}

- (NSString *)description
{
    if (self.isValid) {
        return @"valid";
    } else {
        return [NSString stringWithFormat:@"invalid (%@)", [self.errorMessages componentsJoinedByString:@", "]];
    }
}

@end
