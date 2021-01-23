//
//  YNPOrderedItem.h
//  YenePaySDK
//
//  Created by Ahmed Mohammed Abdurahman on 1/14/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YNPOrderedItem : NSObject <NSCopying>

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *itemName;
@property (nonatomic) double unitPrice;
@property (nonatomic) NSInteger quantity;

@property (nonatomic, readonly) double totalPrice;      // computed

@end

NS_ASSUME_NONNULL_END
