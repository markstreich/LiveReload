
#import <XCTest/XCTest.h>
#import "ATPathSpec.h"


@interface ATPathSpecMultiComponentTests : XCTestCase
@end

@implementation ATPathSpecMultiComponentTests

- (void)testAnyFileIsRootedOption {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"README.txt" syntaxOptions:ATPathSpecSyntaxFlavorGlob];
    XCTAssertEqualObjects([spec description], @"/README.txt", "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
}


- (void)testRootedFile {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"/README.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"/README.txt", "");
    XCTAssertTrue( [spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
}

- (void)testSubfolder {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"docs/*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"docs/*.txt", "");
    XCTAssertTrue(![spec matchesPath:@"hellow.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/hellow.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
}

- (void)testSubfolderMask {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"d*/*.txt" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"d*/*.txt", "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"docs/README.html" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"moredocs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"moredocs/README.html" type:ATPathSpecEntryTypeFile], "");
}

- (void)testPathConstructor {
    ATPathSpec *spec = [ATPathSpec pathSpecMatchingPath:@"docs/readme.txt" type:ATPathSpecEntryTypeFile syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"docs/readme.txt", "");
}

- (void)testFolderMatchIncludesFiles {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"docs/" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"docs/", "");
    XCTAssertTrue( [spec matchesPath:@"docs" type:ATPathSpecEntryTypeFolder], "");
    XCTAssertTrue(![spec matchesPath:@"README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/README.txt" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue(![spec matchesPath:@"moredocs/README.txt" type:ATPathSpecEntryTypeFile], "");
}

- (void)testFolderNotMatchedWhenTypesDiffer {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:@"docs/readme/" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    XCTAssertEqualObjects([spec description], @"docs/readme/", "");
    XCTAssertTrue( [spec matchesPath:@"docs/readme" type:ATPathSpecEntryTypeFolder], "");
    XCTAssertTrue(![spec matchesPath:@"docs/readme" type:ATPathSpecEntryTypeFile], "");
    XCTAssertTrue( [spec matchesPath:@"docs/readme/README.txt" type:ATPathSpecEntryTypeFile], "");
}

@end
