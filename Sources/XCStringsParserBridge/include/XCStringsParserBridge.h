#ifndef XCStringsParserBridge_h
#define XCStringsParserBridge_h

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

// XCStringsParser.framework does not ship headers. The declarations below are
// the typed bridge subset of the interface reported by:
//
//   ipsw class-dump \
//     /path/to/XCStringsParser.framework/Versions/A/XCStringsParser --headers
//
// The dump reports the Swift-backed Objective-C methods using id for most
// object types because the binary's Objective-C encodings do not preserve the
// concrete Swift types. The Foundation and bridge types below retain the
// observed ABI while giving Clang's Swift importer useful types.
@interface XCStrings : NSObject
@property (nonatomic, readonly, copy) NSNumber *version;
@property (nonatomic, readonly, copy) NSString *sourceLanguage;

- (instancetype)initWithSourceLanguage:(NSString *)language NS_SWIFT_NAME(init(sourceLanguage:));
@end

@interface XCStringsSerialization : NSObject
+ (nullable XCStrings *)xcstringsFromPath:(NSString *)path
                                    error:(NSError * _Nullable * _Nullable)error
    __attribute__((swift_error(null_result)))
    NS_SWIFT_NAME(xcstrings(fromPath:));

+ (nullable XCStrings *)xcstringsFromFilename:(NSString *)filename
                                         bundle:(NSBundle *)bundle
                                          error:(NSError * _Nullable * _Nullable)error
    __attribute__((swift_error(null_result)))
    NS_SWIFT_NAME(xcstrings(fromFilename:bundle:));

+ (nullable XCStrings *)xcstringsFromData:(NSData *)data
                                    error:(NSError * _Nullable * _Nullable)error
    __attribute__((swift_error(null_result)))
    NS_SWIFT_NAME(xcstrings(fromData:));

+ (nullable NSString *)jsonStringFromXCStrings:(XCStrings *)xcstrings
                                          error:(NSError * _Nullable * _Nullable)error
    __attribute__((swift_error(null_result)))
    NS_SWIFT_NAME(jsonString(from:));

+ (nullable NSData *)dataFromXCStrings:(XCStrings *)xcstrings
                                 error:(NSError * _Nullable * _Nullable)error
    __attribute__((swift_error(null_result)))
    NS_SWIFT_NAME(data(from:));

+ (void)acquireAccessToFileAtPath:(NSString *)path
                         operation:(id)operation
                 completionHandler:(id)handler;
@end

NS_ASSUME_NONNULL_END

#endif
