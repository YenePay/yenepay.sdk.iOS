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

@interface YNPPaymentOrderManager()

@property (nonatomic, readonly, nonnull) NSString *checkoutEndpoint;

@property (nonatomic, readonly) BOOL isCheckoutInProgress;
@property (nonatomic, copy, nullable) YNPPaymentOrder *paymentOrder;
@property (nonatomic, strong, nullable) YNPPaymentCompletionHandler_t paymentCompletionHandler;

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

// TODO: Handle cases where the app returns to foreground without being launched via the return url
- (BOOL)handleOpenUrl:(NSURL *)url {
    if (![self canHandleUrl:url.absoluteString]) return NO;
    
    YNPPaymentResponse *response = [YNPUrlUtils parsePaymentResponseUrl:url];
    if (response == nil) {
        if (self.isCheckoutInProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorDesc = NSLocalizedString(@"Unable to complete payment.", nil);
                NSString *errorDebugDesc = @"Unable to parse response";
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: errorDesc,
                    NSDebugDescriptionErrorKey: errorDebugDesc
                };
                NSError *error = [NSError errorWithDomain:YNPPaymentErrorDomain
                                                     code:YNPPaymentErrorUnknown
                                                 userInfo:userInfo];
                [self finishCheckoutWithResponse:nil error:error];
            });
        }
        return NO;
    }
    
// TODO: verify response before going any further
    
    if (self.isCheckoutInProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishCheckoutWithResponse:response error:nil];
        });
    } else {
        if (response.isPaymentCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self postPaymentCompletedNotificationWithResponse:response];
            });
        }
    }
    
    return YES;
}

- (void)checkoutWithPaymentOrder:(YNPPaymentOrder *)paymentOrder
        paymentCompletionHandler:(void(^)(YNPPaymentResponse *response, NSError *error))completionHandler {
    
    if (self.isCheckoutInProgress) {
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorDesc = NSLocalizedString(@"A previous checkout flow is still in progress.", nil);
                NSString *errorDebugDesc = @"A previous checkout flow is still in progress.";
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
                
    self.paymentCompletionHandler = completionHandler;
    self.paymentOrder = paymentOrder;
    self.paymentOrder.merchantCode = self.merchantCode;
    self.paymentOrder.ipnUrl = self.ipnUrl;
    self.paymentOrder.returnUrl = self.returnUrl;
        
    PaymentOrderValidationResult *validationResult = [YNPPaymentOrderManager validatePaymentOrder:self.paymentOrder];
    if (!validationResult.isValid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishCheckoutWithResponse:nil error:validationResult.error];
        });
        return;
    } // else...
        
    NSURL *checkoutUrl = [YNPUrlUtils checkoutUrlForPaymentOrder:self.paymentOrder
                                                        endpoint:self.checkoutEndpoint];
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
            [self finishCheckoutWithResponse:nil error:error];
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
            [self finishCheckoutWithResponse:nil error:error];
            return;
        }
    }];
}



- (NSString *)checkoutEndpoint {
    if (self.useSandboxEnabled) {
        return @"https://test.yenepay.com/Home/Process";
    } else {
        return @"https://www.yenepay.com/checkout/Home/Process";
    }
}


- (BOOL)isCheckoutInProgress {
    return self.paymentOrder != nil;
}

- (BOOL)canHandleUrl:(NSString *)url {
    if (self.paymentOrder.returnUrl &&
        [YNPPaymentOrderManager url:url matchesReturnUrl:self.paymentOrder.returnUrl]) {
        return YES;
    } else if (self.returnUrl &&
               [YNPPaymentOrderManager url:url matchesReturnUrl:self.returnUrl]) {
        return YES;
    } else {    
        return NO;
    }
}

- (void)finishCheckoutWithResponse:(YNPPaymentResponse *)response error:(NSError *)error {
    YNPPaymentCompletionHandler_t completionHandler = self.paymentCompletionHandler;
    
    self.paymentOrder = nil;
    self.paymentCompletionHandler = nil;
    
    if (completionHandler) completionHandler(response, error);
    if (response.isPaymentCompleted) [self postPaymentCompletedNotificationWithResponse:response];
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
