//
//  NSString+BRNetworkSSE.m
//  BRNetwork
//
//  Created by bo ren on 2025/4/30.
//

#import "NSString+BRNetworkSSE.h"

@implementation NSString (BRNetworkSSE)

#pragma mark - Public Methods
/*
 1.将参数字典转换为URL查询字符串并拼接到基础URL后
 */
+ (NSString *)getURLQueryString:(NSString *)baseUrl params:(NSDictionary *)params {
    // 参数安全检查
    if (!baseUrl || baseUrl.length == 0) {
        NSLog(@"⚠️ 基础URL不能为空");
        return @"";
    }
    
    if (!params || params.count == 0) {
        return baseUrl; // 无参数直接返回原URL
    }
    
    // 处理嵌套参数，生成扁平化的查询项数组
    NSMutableArray *queryItems = [self flattenDictionary:params parentKey:nil];
    
    if (queryItems.count == 0) {
        return baseUrl;
    }
    
    // 拼接查询字符串（格式：key1=value1&key2=value2）
    NSString *queryString = [queryItems componentsJoinedByString:@"&"];
    
    // 判断基础URL是否已包含查询参数
    NSRange queryRange = [baseUrl rangeOfString:@"?"];
    if (queryRange.location == NSNotFound) {
        // 无现有参数，使用?连接
        return [NSString stringWithFormat:@"%@?%@", baseUrl, queryString];
    } else if (queryRange.location == baseUrl.length - 1) {
        // URL以?结尾，直接拼接
        return [NSString stringWithFormat:@"%@%@", baseUrl, queryString];
    } else {
        // 已有参数，使用&连接
        return [NSString stringWithFormat:@"%@&%@", baseUrl, queryString];
    }
}

#pragma mark - Private Methods
/**
 2.（内部方法）递归扁平化字典结构
 
 @param dictionary 要处理的字典
 @param parentKey 父级键名（用于嵌套结构，顶层传nil）
 @return 扁平化的查询参数项数组（格式为@"key=value"）
 
 @discussion 该方法将嵌套字典转换为扁平化的查询参数项，
 例如 @{@"user": @{@"name": @"Tom"}} 转换为 @[@"user[name]=Tom"]
 */
+ (NSMutableArray *)flattenDictionary:(NSDictionary *)dictionary parentKey:(NSString *)parentKey {
    NSMutableArray *queryItems = [NSMutableArray array];
    
    // 按字母顺序排序键（保证生成的URL具有确定性）
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *key in sortedKeys) {
        id value = dictionary[key];
        
        // 构建当前键名（处理嵌套层级）
        NSString *currentKey = parentKey ?
            [NSString stringWithFormat:@"%@[%@]", parentKey, key] :
            key;
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            // 递归处理嵌套字典
            NSArray *nestedItems = [self flattenDictionary:value parentKey:currentKey];
            [queryItems addObjectsFromArray:nestedItems];
        } else if ([value isKindOfClass:[NSArray class]]) {
            // 处理数组类型参数
            NSArray *arrayItems = [self flattenArray:value parentKey:currentKey];
            [queryItems addObjectsFromArray:arrayItems];
        } else {
            // 基本类型值处理
            NSString *encodedItem = [self urlEncodedQueryItemWithKey:currentKey value:value];
            if (encodedItem) {
                [queryItems addObject:encodedItem];
            }
        }
    }
    
    return queryItems;
}

/**
 3.（内部方法）处理数组类型参数
 
 @param array 要处理的数组
 @param parentKey 父级键名
 @return 扁平化的查询参数项数组
 
 @discussion 示例转换结果:
 @[@"ids[0]=1", @"ids[1]=2", @"ids[2]=3"]
 */
+ (NSArray *)flattenArray:(NSArray *)array parentKey:(NSString *)parentKey {
    NSMutableArray *queryItems = [NSMutableArray array];
    
    [array enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
        // 生成数组索引格式的key（如: filters[0]）
        NSString *currentKey = [NSString stringWithFormat:@"%@[%lu]", parentKey, (unsigned long)idx];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            // 数组元素是字典的情况
            NSArray *nestedItems = [self flattenDictionary:value parentKey:currentKey];
            [queryItems addObjectsFromArray:nestedItems];
        } else if ([value isKindOfClass:[NSArray class]]) {
            // 多维数组情况（递归处理）
            NSArray *nestedItems = [self flattenArray:value parentKey:currentKey];
            [queryItems addObjectsFromArray:nestedItems];
        } else {
            // 基本类型元素
            NSString *encodedItem = [self urlEncodedQueryItemWithKey:currentKey value:value];
            if (encodedItem) {
                [queryItems addObject:encodedItem];
            }
        }
    }];
    
    return [queryItems copy];
}

#pragma mark - URL Encoding Utilities
/**
 * 4.全面兼容的URL编码方案
 * @param key 参数的键
 * @param value 参数的值（支持NSString/NSNumber/BOOL等基础类型）
 * @return 格式为"encodedKey=encodedValue"的字符串，或nil（当输入无效时）
 *
 * @discussion 特性：
 * 1. 严格遵循RFC 3986编码规范
 * 2. 自动处理各种基础数据类型
 * 3. 支持特殊字符场景（如中文、emoji、保留字符）
 * 4. 正确处理空值和异常输入
 */
+ (NSString *)urlEncodedQueryItemWithKey:(NSString *)key value:(id)value {
    // 1. 输入验证
    if (!key || [key isEqual:[NSNull null]] || !value || [value isEqual:[NSNull null]]) {
        return nil;
    }
    
    // 2. 值类型统一处理
    NSString *stringValue = nil;
    if ([value isKindOfClass:[NSString class]]) {
        stringValue = (NSString *)value;
    } else if ([value respondsToSelector:@selector(description)]) {
        // 处理NSNumber、NSDate等基础类型
        stringValue = [value description];
        
        // 特殊处理BOOL类型
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *num = (NSNumber *)value;
            if (strcmp([num objCType], @encode(BOOL)) == 0) {
                stringValue = [num boolValue] ? @"true" : @"false";
            }
        }
    } else {
        // 不支持的类型转换为空字符串
        stringValue = @"";
    }
    
    // 3. 自定义编码字符集（比系统默认更严格）
    NSCharacterSet *allowedChars = [NSCharacterSet characterSetWithCharactersInString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"];
    
    // 4. 分段编码处理（解决系统方法对+号等字符的处理问题）
    NSString * (^encodeComponent)(NSString *) = ^(NSString *component) {
        if (!component) return @"";
        
        // 4.1 先进行百分比编码
        NSString *encoded = [component stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
        
        // 4.2 手动处理系统方法未覆盖的保留字符
        encoded = [encoded stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"#" withString:@"%23"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
        
        return encoded;
    };
    
    // 5. 对键和值分别编码
    NSString *encodedKey = encodeComponent(key);
    NSString *encodedValue = encodeComponent(stringValue);
    
    // 6. 返回拼接结果
    return [NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue];
}

@end
