//
//  ESDefines.h
//  ESFramework
//
//  Created by Elf Sundae on 13-4-19.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#ifndef __ESFW_ESDefines_H
#define __ESFW_ESDefines_H

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Debug Macros
/** Debug */
#ifdef DEBUG
        #define NSLog(fmt, ...)		NSLog((@"%@ [Line: %d] %s " fmt),[[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
        #define NSLog(fmt, ...)
#endif

#pragma mark - ARC

#ifndef __has_feature
#define __has_feature(feature) 0
#endif

/** ARC */
#if __has_feature(objc_arc)
        #define __es_arc_enabled        1
        #define ES_AUTORELEASE(exp)
        #define ES_RELEASE(exp)
        #define ES_RETAIN(exp)
#else
        #define __es_arc_enabled        0
        #define ES_AUTORELEASE(exp) [exp autorelease]
        #define ES_RELEASE(exp)  do { [exp release]; exp = nil; } while(0)
        #define ES_RETAIN(exp) [exp retain]
#endif

#if __es_arc_enabled
        #define ES_STRONG strong
#else
        #define ES_STRONG retain
#endif


/** weak property */
// http://stackoverflow.com/a/8594878/742176
//e.g. @property (nonatomic, es_weak_property) __es_weak id<SomeDelegate> delegate;
#if TARGET_OS_IPHONE && defined(__IPHONE_5_0) && (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0) && __clang__ && (__clang_major__ >= 3)
        #define ES_SDK_SUPPORTS_WEAK 1
#elif TARGET_OS_MAC && defined(__MAC_10_7) && (MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_7) && __clang__ && (__clang_major__ >= 3)
        #define ES_SDK_SUPPORTS_WEAK 1
#else
        #define ES_SDK_SUPPORTS_WEAK 0
#endif

#if ES_SDK_SUPPORTS_WEAK
        #define __es_weak        __weak
        #define es_weak_property weak
#else
        #if __clang__ && (__clang_major__ >= 3)
                #define __es_weak __unsafe_unretained
        #else
                #define __es_weak
        #endif

        #define es_weak_property assign
#endif

/** weak object */
#define __es_typeof(var)         __typeof(&*var)
#if __es_arc_enabled
#define ES_WEAK_VAR(_var, _weak_var)    __es_weak __es_typeof(_var) _weak_var = _var
#else
#define ES_WEAK_VAR(_var, _weak_var)    __block __es_typeof(_var) _weak_var = _var
#endif


/** Release a CoreFoundation object safely. */
#define ES_RELEASE_CF_SAFELY(__REF)             do { if (nil != (__REF)) { CFRelease(__REF); __REF = nil; } } while(0)

#pragma mark - NS_ENUM & NS_OPTIONS
#if (__cplusplus && __cplusplus >= 201103L && (__has_extension(cxx_strong_enums) || __has_feature(objc_fixed_enum))) || (!__cplusplus && __has_feature(objc_fixed_enum))
        #define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
        #if (__cplusplus)
                #define NS_OPTIONS(_type, _name) _type _name; enum : _type
        #else
                #define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
        #endif
#else
        #define NS_ENUM(_type, _name) _type _name; enum
        #define NS_OPTIONS(_type, _name) _type _name; enum
#endif

#pragma mark - 
#define ES_IS_MASK_SET(value, flag)  (((value) & (flag)) == (flag))


/** LocalizedString */
//Short hand NSLocalizedString, doesn't need 2 parameters
#define LocalizedString(s) NSLocalizedString(s,s)
// LocalizedString with an additionl parameter for formatting
#define LocalizedStringWithFormat(s,...) [NSString stringWithFormat:NSLocalizedString(s,s),##__VA_ARGS__]

/** __attribute__ deprecated */
#if defined(__GNUC__) && (__GNUC__ >= 4) && defined(__APPLE_CC__) && (__APPLE_CC__ >= 5465)
        #define ES_DEPRECATED_ATTRIBUTE __attribute__((deprecated))
#else
        #define ES_DEPRECATED_ATTRIBUTE
#endif

////////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Color Helper

#define UIColorFromRGB(r,g,b)                   [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define UIColorFromRGBA(r,g,b,a)                [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
// e.g. UIColorFromRGBHex(0xCECECE);
#define UIColorFromRGBHex(rgbValue)     [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
// e.g. UIColorFromRGBAHex(0xCECECE, 0.8);
#define UIColorFromRGBAHex(rgbValue,a) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]



/////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - SDK Compatibility


typedef NS_ENUM(NSInteger, ESNSTextAlignment) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
        ESNSTextAlignmentLeft           = NSTextAlignmentLeft,
        ESNSTextAlignmentCenter         = NSTextAlignmentCenter,
        ESNSTextAlignmentRight          = NSTextAlignmentRight,
        ESNSTextAlignmentJustified      = NSTextAlignmentJustified,
        ESNSTextAlignmentNatural        = NSTextAlignmentNatural,
#else
        ESNSTextAlignmentLeft           = UITextAlignmentLeft,
        ESNSTextAlignmentCenter         = UITextAlignmentCenter,
        ESNSTextAlignmentRight          = UITextAlignmentRight,
#endif 
};

typedef NS_ENUM(NSInteger, ESNSLineBreakMode) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
        ESNSLineBreakByWordWrapping       = NSLineBreakByWordWrapping,
        ESNSLineBreakByCharWrapping       = NSLineBreakByCharWrapping,
        ESNSLineBreakByClipping           = NSLineBreakByClipping,
        ESNSLineBreakByTruncatingHead     = NSLineBreakByTruncatingHead,
        ESNSLineBreakByTruncatingTail     = NSLineBreakByTruncatingTail,
        ESNSLineBreakByTruncatingMiddle   = NSLineBreakByTruncatingMiddle,
#else
        ESNSLineBreakByWordWrapping       = UILineBreakModeWordWrap,
        ESNSLineBreakByCharWrapping       = UILineBreakModeCharacterWrap,
        ESNSLineBreakByClipping           = UILineBreakModeClip,
        ESNSLineBreakByTruncatingHead     = UILineBreakModeHeadTruncation,
        ESNSLineBreakByTruncatingTail     = UILineBreakModeTailTruncation,
        ESNSLineBreakByTruncatingMiddle   = UILineBreakModeMiddleTruncation,        
#endif
};


#endif
