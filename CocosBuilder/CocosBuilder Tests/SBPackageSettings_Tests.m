//
//  PackageSettings_Tests.m
//  CocosBuilder
//
//  Created by Nicky Weber on 21.07.14.
//
//

#import <XCTest/XCTest.h>
#import "SBPackageSettings.h"
#import "RMPackage.h"
#import "PublishOSSettings.h"
#import "FileSystemTestCase.h"
#import "SBAssserts.h"
#import "MiscConstants.h"
#import "CCBPublisherTypes.h"

@interface SBPackageSettings_Tests : FileSystemTestCase

@property (nonatomic, strong) RMPackage *package;
@property (nonatomic, strong) SBPackageSettings *packagePublishSettings;

@end


@implementation SBPackageSettings_Tests

- (void)setUp
{
    [super setUp];

    self.package = [[RMPackage alloc] init];
    _package.dirPath = [self fullPathForFile:@"/foo/project.cocosbuilder/Packages/mypackage.ccbpack"];

    self.packagePublishSettings = [[SBPackageSettings alloc] initWithPackage:_package];

    [self createFolders:@[@"/foo/project.cocosbuilder/Packages/mypackage.ccbpack"]];
}

- (void)testInitialValuesAndKVCPaths
{
    XCTAssertTrue(_packagePublishSettings.publishToMainProject);
    XCTAssertFalse(_packagePublishSettings.publishToZip);
    XCTAssertFalse(_packagePublishSettings.publishToCustomOutputDirectory);

    PublishOSSettings *osSettingsIOS = [_packagePublishSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    XCTAssertNotNil(osSettingsIOS);

    PublishOSSettings *osSettingsTVOS = [_packagePublishSettings settingsForOsType:kCCBPublisherOSTypeTVOS];
    XCTAssertNotNil(osSettingsTVOS);
    
    PublishOSSettings *osSettingsIOSKVC = [_packagePublishSettings valueForKeyPath:@"osSettings.ios"];
    XCTAssertNotNil(osSettingsIOSKVC);
}

- (void)testPersistency
{
    _packagePublishSettings.customOutputDirectory = @"foo";
    _packagePublishSettings.publishToMainProject = NO;
    _packagePublishSettings.publishToZip = NO;
    _packagePublishSettings.publishToCustomOutputDirectory = YES;
    _packagePublishSettings.publishEnvironment = kCCBPublishEnvironmentRelease;
    _packagePublishSettings.resourceAutoScaleFactor = 3;

    PublishOSSettings *osSettingsIOS = [_packagePublishSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    osSettingsIOS.audio_quality = 8;
    osSettingsIOS.resolutions = @[@"phone"];
    [_packagePublishSettings setOSSettings:osSettingsIOS forOsType:kCCBPublisherOSTypeIOS];

    PublishOSSettings *osSettingsTVOS = [_packagePublishSettings settingsForOsType:kCCBPublisherOSTypeTVOS];
    osSettingsTVOS.audio_quality = 8;
    osSettingsTVOS.resolutions = @[@"phone"];
    [_packagePublishSettings setOSSettings:osSettingsTVOS forOsType:kCCBPublisherOSTypeTVOS];
    
    [_packagePublishSettings store];

    [self assertFileExists:@"/foo/project.cocosbuilder/Packages/mypackage.ccbpack/Package.plist"];


    SBPackageSettings *settingsLoaded = [[SBPackageSettings alloc] initWithPackage:_package];
    [settingsLoaded load];

    XCTAssertEqual(_packagePublishSettings.publishToMainProject, settingsLoaded.publishToMainProject);
    SBAssertStringsEqual(_packagePublishSettings.customOutputDirectory, settingsLoaded.customOutputDirectory);
    XCTAssertEqual(_packagePublishSettings.publishEnvironment, settingsLoaded.publishEnvironment);
    XCTAssertEqual(_packagePublishSettings.publishToZip, settingsLoaded.publishToZip);
    XCTAssertEqual(_packagePublishSettings.publishToCustomOutputDirectory, settingsLoaded.publishToCustomOutputDirectory);
    XCTAssertEqual(_packagePublishSettings.resourceAutoScaleFactor, settingsLoaded.resourceAutoScaleFactor);

    PublishOSSettings *osSettingsIOSLoaded = [settingsLoaded settingsForOsType:kCCBPublisherOSTypeIOS];
    XCTAssertEqual(osSettingsIOSLoaded.audio_quality, osSettingsIOS.audio_quality);
    XCTAssertTrue([osSettingsIOSLoaded.resolutions containsObject:RESOLUTION_PHONE]);
    XCTAssertFalse([osSettingsIOSLoaded.resolutions containsObject:RESOLUTION_TABLET_HD]);
 
    PublishOSSettings *osSettingsTVOSLoaded = [settingsLoaded settingsForOsType:kCCBPublisherOSTypeTVOS];
    XCTAssertEqual(osSettingsTVOSLoaded.audio_quality, osSettingsTVOS.audio_quality);
    XCTAssertTrue([osSettingsTVOSLoaded.resolutions containsObject:RESOLUTION_PHONE]);
    XCTAssertFalse([osSettingsTVOSLoaded.resolutions containsObject:RESOLUTION_TABLET_HD]);
}

- (void)testMigrationDefaultScale
{
    NSDictionary *values = @{
            @"outputDir" : @"foo",
            @"publishEnv" : @1,
            @"publishToCustomDirectory" : @YES,
            @"publishToMainProject" : @NO,
            @"publishToZip" : @NO
    };

    [values writeToFile:[self fullPathForFile:@"/foo/project.cocosbuilder/Packages/mypackage.ccbpack/Package.plist"] atomically:YES];

    [_packagePublishSettings load];

    XCTAssertEqual(_packagePublishSettings.resourceAutoScaleFactor, DEFAULT_TAG_VALUE_GLOBAL_DEFAULT_SCALING);
}

- (void)testEffectiveOutputDir
{
    _packagePublishSettings.customOutputDirectory = @"foo";
    _packagePublishSettings.publishToCustomOutputDirectory = YES;

    SBAssertStringsEqual(_packagePublishSettings.effectiveOutputDirectory, @"foo");

    _packagePublishSettings.publishToCustomOutputDirectory = NO;

    SBAssertStringsEqual(_packagePublishSettings.effectiveOutputDirectory, DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES);

    _packagePublishSettings.customOutputDirectory = nil;
    _packagePublishSettings.publishToCustomOutputDirectory = YES;
    SBAssertStringsEqual(_packagePublishSettings.effectiveOutputDirectory, DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES);

    _packagePublishSettings.customOutputDirectory = @"    ";
    _packagePublishSettings.publishToCustomOutputDirectory = YES;
    SBAssertStringsEqual(_packagePublishSettings.effectiveOutputDirectory, DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES);
}

@end
