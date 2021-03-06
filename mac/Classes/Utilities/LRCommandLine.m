
#import "LRCommandLine.h"
#import "ATFunctionalStyle.h"



NSArray *LRParseCommandLineSpec(id spec) {
    if (spec == nil || spec == [NSNull null])
        return @[];
    if ([spec isKindOfClass:NSArray.class]) {
        return spec;
    }
    if ([spec isKindOfClass:NSString.class]) {
        return [spec argumentsArrayUsingBourneQuotingStyle];
    }
    NSCAssert(NO, @"Invalid command line spec: %@", spec);
    return @[];
}



@implementation ATQuotingStyle {
    NSCharacterSet *_safeCharacterSet;
    NSString *_escapeCharacterString;

    NSDictionary *_invertedEscapeSequences;
}

- (id)initWithStartString:(NSString *)startString endString:(NSString *)endString escapeCharacter:(unichar)escapeCharacter escapeSequences:(NSDictionary *)escapeSequences {
    self = [super init];
    if (self) {
        _startString = [startString copy];
        _endString = [endString copy];
        _escapeCharacter = escapeCharacter;
        _escapeSequences = [escapeSequences copy];
        _escapeCharacterString = (_escapeCharacter != 0 ? [NSString stringWithCharacters:&_escapeCharacter length:1] : @"");

        NSMutableCharacterSet *unsafeCharacterSet = [NSMutableCharacterSet new];
        if (_escapeCharacter != 0) {
            [unsafeCharacterSet addCharactersInRange:NSMakeRange(_escapeCharacter, 1)];
        }
        [unsafeCharacterSet addCharactersInString:[_endString substringToIndex:1]];
        for (NSString *sequence in [_escapeSequences allKeys]) {
            [unsafeCharacterSet addCharactersInString:[sequence substringToIndex:1]];
        }
        _safeCharacterSet = [unsafeCharacterSet invertedSet];

        NSMutableDictionary *invertedEscapeSequences = [NSMutableDictionary new];
        [_escapeSequences enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            invertedEscapeSequences[obj] = key;
        }];
        _invertedEscapeSequences = [invertedEscapeSequences copy];
    }
    return self;
}

+ (id)quotingStyleWithStartString:(NSString *)startString endString:(NSString *)endString escapeCharacter:(unichar)escapeCharacter escapeSequences:(NSDictionary *)escapeSequences {
    return [[[self class] alloc] initWithStartString:startString endString:endString escapeCharacter:escapeCharacter escapeSequences:escapeSequences];
}

- (BOOL)scanQuotedStringWithScanner:(NSScanner *)scanner intoString:(NSString **)string {
    if (![scanner scanString:_startString intoString:NULL])
        return NO;

    NSMutableString *result = [NSMutableString new];
    NSString * __autoreleasing component;

    NSString *scannedString = scanner.string;
    NSUInteger scannedStringLength = scannedString.length;

    while (!scanner.isAtEnd) {
        if ([scanner scanCharactersFromSet:_safeCharacterSet intoString:&component]) {
            [result appendString:component];
        }

        if (scanner.isAtEnd)
            break;

        for (NSString *sequence in [_escapeSequences allKeys]) {
            if ([scanner scanString:sequence intoString:NULL]) {
                [result appendString:_escapeSequences[sequence]];
                goto continue_outer_loop;
            }
        }

        if (_escapeCharacter != 0) {
            NSUInteger location = scanner.scanLocation;
            unichar ch = [scannedString characterAtIndex:location];
            if (_escapeCharacter == ch) {
                ++location;
                if (location < scannedStringLength) {
                    [result appendString:[scannedString substringWithRange:NSMakeRange(location, 1)]];
                    ++location;
                }

                scanner.scanLocation = location;
                goto continue_outer_loop;
            }
        }

        if ([scanner scanString:_endString intoString:NULL]) {
            break;
        }

        NSAssert(NO, @"Unreachabe");

    continue_outer_loop:
        ;
    }

    if (string)
        *string = [result copy];
    return YES;
}

- (BOOL)isPerfectQuotingStyleForString:(NSString *)string {
    return ([string stringByTrimmingCharactersInSet:_safeCharacterSet].length == 0);
}

- (NSString *)quoteString:(NSString *)string {
    NSMutableString *result = [NSMutableString new];
    [result appendString:_startString];

    NSString * __autoreleasing component;

    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    while (!scanner.isAtEnd) {
        if ([scanner scanCharactersFromSet:_safeCharacterSet intoString:&component]) {
            [result appendString:component];
        }

        if (scanner.isAtEnd)
            break;

        for (NSString *sequence in [_invertedEscapeSequences allKeys]) {
            if ([scanner scanString:sequence intoString:NULL]) {
                [result appendString:_invertedEscapeSequences[sequence]];
                goto continue_outer_loop;
            }
        }

        NSUInteger location = scanner.scanLocation;
        unichar ch = [string characterAtIndex:location];

        if (_escapeCharacter != 0) {
            [result appendString:_escapeCharacterString];
        }

        // if there's no escape sequence and no escape character, we'll just append it verbatim -- not much else that we can do
        [result appendString:[NSString stringWithCharacters:&ch length:1]];
        scanner.scanLocation = location + 1;

    continue_outer_loop:
        ;
    }

    [result appendString:_endString];
    return [result copy];
}

@end


@interface NSString (ATQuoting)

- (NSArray *)AT_componentsSeparatedByCharactersInSet:(NSCharacterSet *)delimiters usingQuotingStyles:(NSArray *)quotingStyles;

@end


@implementation NSString (ATQuoting)

- (NSArray *)AT_componentsSeparatedByCharactersInSet:(NSCharacterSet *)delimiters usingQuotingStyles:(NSArray *)quotingStyles {
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    
    NSMutableArray *result = [NSMutableArray new];
    NSString * __autoreleasing component;

    [scanner scanCharactersFromSet:delimiters intoString:NULL];

    while (!scanner.isAtEnd) {
        for (ATQuotingStyle *quotingStyle in quotingStyles) {
            if ([quotingStyle scanQuotedStringWithScanner:scanner intoString:&component]) {
                [result addObject:component];
                goto next;
            }
        }

        [scanner scanUpToCharactersFromSet:delimiters intoString:&component];
        [result addObject:component];

    next:
        [scanner scanCharactersFromSet:delimiters intoString:NULL];
    }

    return [result copy];
}

- (NSString *)AT_optionallyQuotedStringAvoidingUnquotedCharactersInSet:(NSCharacterSet *)unsafeCharacters usingQuotingStyles:(NSArray *)quotingStyles {
    if (quotingStyles.count == 0)
        return self;
    if ([self stringByTrimmingCharactersInSet:[unsafeCharacters invertedSet]].length == 0)
        return self;

    for (ATQuotingStyle *quotingStyle in quotingStyles) {
        if ([quotingStyle isPerfectQuotingStyleForString:self])
            return [quotingStyle quoteString:self];
    }

    ATQuotingStyle *quotingStyle = [quotingStyles firstObject];
    return [quotingStyle quoteString:self];
}

@end


static NSArray *LRBourneCommandLineQuotingStyles() {
    static NSArray *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = @[
            [ATQuotingStyle quotingStyleWithStartString:@"'" endString:@"'" escapeCharacter:'\\' escapeSequences:@{}],
            [ATQuotingStyle quotingStyleWithStartString:@"\"" endString:@"\"" escapeCharacter:'\\' escapeSequences:@{}],
        ];
    });
    return result;
}



@implementation NSString (LRCommandLine)

- (NSArray *)argumentsArrayWithoutQuoting {
    NSArray *components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [components filteredArrayUsingBlock:^BOOL(NSString *value) {
        return value.length > 0;
    }];
}

- (NSArray *)argumentsArrayUsingBourneQuotingStyle {
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [self AT_componentsSeparatedByCharactersInSet:whitespace usingQuotingStyles:LRBourneCommandLineQuotingStyles()];
}

@end

@implementation NSArray (LRCommandLine)

- (NSString *)quotedArgumentStringUsingBourneQuotingStyle {
    static NSCharacterSet *unsafeCharacterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [set addCharactersInString:@"'\\\""];
        unsafeCharacterSet = [set copy];
    });

    NSArray *quotingStyles = LRBourneCommandLineQuotingStyles();

    return [[self arrayByMappingElementsUsingBlock:^id(NSString *item) {
        return [item AT_optionallyQuotedStringAvoidingUnquotedCharactersInSet:unsafeCharacterSet usingQuotingStyles:quotingStyles];
    }] componentsJoinedByString:@" "];
}

@end
