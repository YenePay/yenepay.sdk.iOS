//
//  YNPPaymentResponse.m
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import "YNPPaymentResponse.h"
#import "YNPPaymentResponse_internal.h"

@implementation YNPPaymentResponse

- (BOOL)isPending {
    switch (self.status) {
        case YNPPaymentStatusNew:
        case YNPPaymentStatusWaiting:
        case YNPPaymentStatusProcessing:
        case YNPPaymentStatusVerifying:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)isPaymentCompleted {
    switch (self.status) {
        case YNPPaymentStatusCompleted:
        case YNPPaymentStatusPaid:
        case YNPPaymentStatusDelivered:
            return YES;
        default:
            return NO;
    }
}

//- (NSString *)verificationString {
//    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
//    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
//    currencyFormatter.currencySymbol = @"";
//    currencyFormatter.currencyDecimalSeparator = @".";
//    currencyFormatter.currencyGroupingSeparator = @",";
//    currencyFormatter.maximumFractionDigits = 2;
//    currencyFormatter.minimumFractionDigits = 2;
//    currencyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"US"];
//
//    NSMutableString *verifStr = [NSMutableString string];
//    [verifStr appendFormat:@"TotalAmount=%@", [currencyFormatter stringFromNumber:@(self.grandTotal)]];
//
//    return [verifStr copy];
//}


- (void)setStatusAndStatusTextFromString:(NSString *__nullable)statusText {
    YNPPaymentStatus status = YNPPaymentStatusUnkown;
    if (statusText) {
        status = [YNPPaymentResponse statusFromStatusText:statusText];
        if (status == YNPPaymentStatusUnkown) {
            NSCharacterSet *nonDecimalCharSet = NSCharacterSet.decimalDigitCharacterSet.invertedSet;
            if ([statusText rangeOfCharacterFromSet:nonDecimalCharSet].length == 0) {
                status = [YNPPaymentResponse statusFromStatusInt:statusText.intValue];
            }
        }
    }
    
    self.status = status;
    self.statusText = [YNPPaymentResponse statusTextFromStatusInt:status];
}


+ (YNPPaymentStatus)statusFromStatusInt:(int)statusInt {
    if ((statusInt < YNPMinPaymentStatus) || (statusInt > YNPMaxPaymentStatus)) {
        return YNPPaymentStatusUnkown;
    } else {
        return (YNPPaymentStatus)statusInt;
    }
}

+ (NSString *)statusTextFromStatusInt:(NSInteger)statusInt {
    switch (statusInt) {
        case YNPPaymentStatusNew:
        case YNPPaymentStatusProcessing:
        case YNPPaymentStatusWaiting:
            return @"Pending";
            
        case YNPPaymentStatusCanceled:
            return @"Canceled";
            
        case YNPPaymentStatusCompleted:
        case YNPPaymentStatusPaid:
        case YNPPaymentStatusDelivered:
            return @"Completed";
            
        case YNPPaymentStatusVerifying:
            return @"Processing";
    
        case YNPPaymentStatusExpired:
            return @"Expired";
            
        default:
            return @"Unknown";;
    }
}

+ (YNPPaymentStatus)statusFromStatusText:(NSString *)statusText {
    statusText = [statusText lowercaseString];
    if ([statusText isEqualToString:@"paid"]) return YNPPaymentStatusPaid;
    if ([statusText isEqualToString:@"completed"]) return YNPPaymentStatusCompleted;
    if ([statusText isEqualToString:@"canceled"]) return YNPPaymentStatusCanceled;
    if ([statusText isEqualToString:@"delivered"]) return YNPPaymentStatusDelivered;
    if ([statusText isEqualToString:@"disputed"]) return YNPPaymentStatusDisputed;
    if ([statusText isEqualToString:@"error"]) return YNPPaymentStatusError;
    if ([statusText isEqualToString:@"expired"]) return YNPPaymentStatusExpired;
    if ([statusText isEqualToString:@"new"]) return YNPPaymentStatusNew;
    if ([statusText isEqualToString:@"waiting"]) return YNPPaymentStatusWaiting;
    if ([statusText isEqualToString:@"verifying"]) return YNPPaymentStatusVerifying;
    if ([statusText isEqualToString:@"processing"]) return YNPPaymentStatusProcessing;
    return YNPPaymentStatusUnkown;
}

@end
