//
//  MODBinary.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 28/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODBinary ()
@property(nonatomic, assign, readwrite) char binaryType;
@property(nonatomic, copy, readwrite) NSData *binaryData;

@end

@implementation MODBinary

+ (BOOL)isValidDataType:(unsigned char)dataType
{
    BOOL result = NO;
    
    switch (dataType) {
        case BSON_SUBTYPE_BINARY:
        case BSON_SUBTYPE_FUNCTION:
        case BSON_SUBTYPE_BINARY_DEPRECATED:
        case BSON_SUBTYPE_UUID_DEPRECATED:
        case BSON_SUBTYPE_UUID:
        case BSON_SUBTYPE_MD5:
        case BSON_SUBTYPE_USER:
            result = YES;
            break;
            
        default:
            break;
    }
    return result;
}

- (instancetype)initWithData:(NSData *)data binaryType:(unsigned char)binaryType
{
    return [self initWithBytes:data.bytes length:data.length binaryType:binaryType];
}

- (instancetype)initWithBytes:(const void *)bytes length:(NSUInteger)length binaryType:(unsigned char)binaryType
{
    if (self = [self init]) {
        self.binaryData = [NSData dataWithBytes:bytes length:length];
        self.binaryType = binaryType;
    }
    return self;
}

- (void)dealloc
{
    self.binaryData = nil;
    MOD_SUPER_DEALLOC();
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    NSString *result;
    
    if (!strictJSON && pretty) {
        result = [NSString stringWithFormat:@"BinData(%x, \"%@\")", (int)self.binaryType, self.binaryData.mod_base64String];
    } else if (!strictJSON) {
        result = [NSString stringWithFormat:@"BinData(%x,\"%@\")", (int)self.binaryType, self.binaryData.mod_base64String];
    } else if (pretty) {
        result = [NSString stringWithFormat:@"{ \"$binary\" : \"%@\", \"$type\" : \"%d\" }", self.binaryData.mod_base64String, (int)self.binaryType];
    } else {
        result = [NSString stringWithFormat:@"{\"$binary\":\"%@\",\"$type\":\"%d\"}", self.binaryData.mod_base64String, (int)self.binaryType];
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:self.class]) {
        return [[object binaryData] isEqual:self.binaryData] && [object binaryType] == self.binaryType;
    }
    return NO;
}

@end
