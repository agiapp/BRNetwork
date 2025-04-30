//
//  NSString+BRNetworkSSE.h
//  BRNetwork
//
//  Created by bo ren on 2025/4/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @category NSString(BRNetworkSSE)
 @brief 用于处理网络请求中URL和参数的NSString扩展方法
 @discussion 该分类提供了将参数字典转换为URL查询字符串的功能，
 支持嵌套字典和数组的复杂参数结构，自动进行URL编码。
 */
@interface NSString (BRNetworkSSE)

/**
 1.将参数字典转换为URL查询字符串并拼接到基础URL后
 
 @param baseUrl 基础URL字符串（不包含查询参数）
 @param params 参数字典，支持嵌套的NSDictionary和NSArray
 @return 完整的URL字符串，包含查询参数
 
 @discussion 示例用法:
 @code
 NSDictionary *params = @{@"q": @"search", @"filters": @{@"type": @"book"}};
 NSString *url = [NSString getURLQueryString:@"https://api.example.com" params:params];
 // 结果: "https://api.example.com?q=search&filters[type]=book"
 @endcode
 
 @note 自动处理以下情况:
 - 参数值自动进行URL编码
 - 支持嵌套字典（转换为key[subKey]格式）
 - 支持数组（转换为key[0]、key[1]格式）
 - 自动处理基础URL是否已包含参数的情况（使用?或&连接）
 */
+ (NSString *)getURLQueryString:(NSString *)baseUrl params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
