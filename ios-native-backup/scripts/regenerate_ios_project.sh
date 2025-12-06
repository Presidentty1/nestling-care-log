#!/bin/bash

# Regenerate iOS Xcode project from scratch
# This preserves all source files but creates a fresh project structure

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"
NESTLING_DIR="$IOS_DIR/Nestling"
BACKUP_DIR="$IOS_DIR/backup_$(date +%Y%m%d_%H%M%S)"

echo "🔄 Regenerating iOS Project"
echo "=========================="
echo ""
echo "⚠️  WARNING: This will recreate the Xcode project structure"
echo "   All source files will be preserved"
echo "   Project settings will be reset to defaults"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# Step 1: Create backup
echo ""
echo "1️⃣  Creating backup..."
mkdir -p "$BACKUP_DIR"
cp -R "$NESTLING_DIR" "$BACKUP_DIR/Nestling" 2>/dev/null || true
echo "✅ Backup created at: $BACKUP_DIR"

# Step 2: Kill Xcode
echo ""
echo "2️⃣  Closing Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

# Step 3: Backup source files
echo ""
echo "3️⃣  Backing up source files..."
SOURCE_BACKUP="$BACKUP_DIR/sources"
mkdir -p "$SOURCE_BACKUP"

# Backup all Swift files and important directories
if [ -d "$NESTLING_DIR/Nestling" ]; then
    cp -R "$NESTLING_DIR/Nestling" "$SOURCE_BACKUP/" 2>/dev/null || true
fi
if [ -d "$NESTLING_DIR/NestlingTests" ]; then
    cp -R "$NESTLING_DIR/NestlingTests" "$SOURCE_BACKUP/" 2>/dev/null || true
fi
if [ -d "$NESTLING_DIR/NestlingUITests" ]; then
    cp -R "$NESTLING_DIR/NestlingUITests" "$SOURCE_BACKUP/" 2>/dev/null || true
fi
if [ -d "$NESTLING_DIR/Nestling.xcodeproj/Assets.xcassets" ]; then
    mkdir -p "$SOURCE_BACKUP/Assets.xcassets"
    cp -R "$NESTLING_DIR/Nestling.xcodeproj/Assets.xcassets" "$SOURCE_BACKUP/" 2>/dev/null || true
fi

echo "✅ Source files backed up"

# Step 4: Remove old project files (keep source)
echo ""
echo "4️⃣  Removing old project files..."
cd "$NESTLING_DIR"
rm -rf Nestling.xcodeproj
rm -rf build/
rm -rf .build/
find . -name "*.xcuserstate" -delete
find . -name "*.xcuserdatad" -type d -exec rm -rf {} + 2>/dev/null || true
echo "✅ Old project files removed"

# Step 5: Create new Xcode project structure
echo ""
echo "5️⃣  Creating new Xcode project structure..."
mkdir -p "Nestling.xcodeproj/project.xcworkspace"
mkdir -p "Nestling.xcodeproj/xcshareddata/swiftpm"

# Create workspace file
cat > "Nestling.xcodeproj/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF

echo "✅ Project structure created"

# Step 6: Generate fresh project.pbxproj
echo ""
echo "6️⃣  Generating fresh project.pbxproj..."
python3 << 'PYTHON_SCRIPT' > "Nestling.xcodeproj/project.pbxproj"
import secrets
import uuid

def generate_xcode_uuid():
    """Generate a 24-character hex UUID in Xcode format"""
    return secrets.token_hex(12).upper()

# Generate all UUIDs
project_uuid = generate_xcode_uuid()
main_group_uuid = generate_xcode_uuid()
products_group_uuid = generate_xcode_uuid()
nestling_target_uuid = generate_xcode_uuid()
tests_target_uuid = generate_xcode_uuid()
uitests_target_uuid = generate_xcode_uuid()

nestling_app_uuid = generate_xcode_uuid()
tests_bundle_uuid = generate_xcode_uuid()
uitests_bundle_uuid = generate_xcode_uuid()

nestling_group_uuid = generate_xcode_uuid()
tests_group_uuid = generate_xcode_uuid()
uitests_group_uuid = generate_xcode_uuid()

sources_phase_uuid = generate_xcode_uuid()
frameworks_phase_uuid = generate_xcode_uuid()
resources_phase_uuid = generate_xcode_uuid()

tests_sources_uuid = generate_xcode_uuid()
tests_frameworks_uuid = generate_xcode_uuid()
tests_resources_uuid = generate_xcode_uuid()

uitests_sources_uuid = generate_xcode_uuid()
uitests_frameworks_uuid = generate_xcode_uuid()
uitests_resources_uuid = generate_xcode_uuid()

test_dependency_uuid = generate_xcode_uuid()
uitest_dependency_uuid = generate_xcode_uuid()
test_proxy_uuid = generate_xcode_uuid()
uitest_proxy_uuid = generate_xcode_uuid()

debug_config_uuid = generate_xcode_uuid()
release_config_uuid = generate_xcode_uuid()
project_debug_config_uuid = generate_xcode_uuid()
project_release_config_uuid = generate_xcode_uuid()
target_debug_config_uuid = generate_xcode_uuid()
target_release_config_uuid = generate_xcode_uuid()
tests_debug_config_uuid = generate_xcode_uuid()
tests_release_config_uuid = generate_xcode_uuid()
uitests_debug_config_uuid = generate_xcode_uuid()
uitests_release_config_uuid = generate_xcode_uuid()

project_config_list_uuid = generate_xcode_uuid()
target_config_list_uuid = generate_xcode_uuid()
tests_config_list_uuid = generate_xcode_uuid()
uitests_config_list_uuid = generate_xcode_uuid()

# Generate project.pbxproj content
project_content = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 54;
	objects = {{

/* Begin PBXContainerItemProxy section */
		{test_proxy_uuid} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {project_uuid} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {nestling_target_uuid};
			remoteInfo = Nestling;
		}};
		{uitest_proxy_uuid} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {project_uuid} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {nestling_target_uuid};
			remoteInfo = Nestling;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		{nestling_app_uuid} /* Nestling.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Nestling.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{tests_bundle_uuid} /* NestlingTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = NestlingTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
		{uitests_bundle_uuid} /* NestlingUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = NestlingUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase_uuid} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{tests_frameworks_uuid} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{uitests_frameworks_uuid} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group_uuid} = {{
			isa = PBXGroup;
			children = (
				{nestling_group_uuid} /* Nestling */,
				{tests_group_uuid} /* NestlingTests */,
				{uitests_group_uuid} /* NestlingUITests */,
				{products_group_uuid} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{nestling_group_uuid} /* Nestling */ = {{
			isa = PBXGroup;
			children = (
			);
			path = Nestling;
			sourceTree = "<group>";
		}};
		{tests_group_uuid} /* NestlingTests */ = {{
			isa = PBXGroup;
			children = (
			);
			path = NestlingTests;
			sourceTree = "<group>";
		}};
		{uitests_group_uuid} /* NestlingUITests */ = {{
			isa = PBXGroup;
			children = (
			);
			path = NestlingUITests;
			sourceTree = "<group>";
		}};
		{products_group_uuid} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{nestling_app_uuid} /* Nestling.app */,
				{tests_bundle_uuid} /* NestlingTests.xctest */,
				{uitests_bundle_uuid} /* NestlingUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{nestling_target_uuid} /* Nestling */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list_uuid} /* Build configuration list for PBXNativeTarget "Nestling" */;
			buildPhases = (
				{sources_phase_uuid} /* Sources */,
				{frameworks_phase_uuid} /* Frameworks */,
				{resources_phase_uuid} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Nestling;
			productName = Nestling;
			productReference = {nestling_app_uuid} /* Nestling.app */;
			productType = "com.apple.product-type.application";
		}};
		{tests_target_uuid} /* NestlingTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {tests_config_list_uuid} /* Build configuration list for PBXNativeTarget "NestlingTests" */;
			buildPhases = (
				{tests_sources_uuid} /* Sources */,
				{tests_frameworks_uuid} /* Frameworks */,
				{tests_resources_uuid} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{test_dependency_uuid} /* PBXTargetDependency */,
			);
			name = NestlingTests;
			productName = NestlingTests;
			productReference = {tests_bundle_uuid} /* NestlingTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
		{uitests_target_uuid} /* NestlingUITests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {uitests_config_list_uuid} /* Build configuration list for PBXNativeTarget "NestlingUITests" */;
			buildPhases = (
				{uitests_sources_uuid} /* Sources */,
				{uitests_frameworks_uuid} /* Frameworks */,
				{uitests_resources_uuid} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{uitest_dependency_uuid} /* PBXTargetDependency */,
			);
			name = NestlingUITests;
			productName = NestlingUITests;
			productReference = {uitests_bundle_uuid} /* NestlingUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{nestling_target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
					}};
					{tests_target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
						TestTargetID = {nestling_target_uuid};
					}};
					{uitests_target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
						TestTargetID = {nestling_target_uuid};
					}};
				}};
			}};
			buildConfigurationList = {project_config_list_uuid} /* Build configuration list for PBXProject "Nestling" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_uuid};
			productRefGroup = {products_group_uuid} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{nestling_target_uuid} /* Nestling */,
				{tests_target_uuid} /* NestlingTests */,
				{uitests_target_uuid} /* NestlingUITests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase_uuid} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{tests_resources_uuid} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{uitests_resources_uuid} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase_uuid} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{tests_sources_uuid} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{uitests_sources_uuid} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{test_dependency_uuid} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {nestling_target_uuid} /* Nestling */;
			targetProxy = {test_proxy_uuid} /* PBXContainerItemProxy */;
		}};
		{uitest_dependency_uuid} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {nestling_target_uuid} /* Nestling */;
			targetProxy = {uitest_proxy_uuid} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{project_debug_config_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{project_release_config_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{target_debug_config_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_NSMicrophoneUsageDescription = "Nestling needs microphone access to analyze your baby's cry patterns and provide insights.";
				INFOPLIST_KEY_NSUserNotificationsUsageDescription = "Nestling uses notifications to remind you about feedings, diaper changes, and sleep schedules.";
				INFOPLIST_KEY_NSFaceIDUsageDescription = "Nestling uses Face ID to securely protect your baby's data.";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nestling.Nestling;
				PRODUCT_NAME = "$(TARGET_NAME)";
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{target_release_config_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_NSMicrophoneUsageDescription = "Nestling needs microphone access to analyze your baby's cry patterns and provide insights.";
				INFOPLIST_KEY_NSUserNotificationsUsageDescription = "Nestling uses notifications to remind you about feedings, diaper changes, and sleep schedules.";
				INFOPLIST_KEY_NSFaceIDUsageDescription = "Nestling uses Face ID to securely protect your baby's data.";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nestling.Nestling;
				PRODUCT_NAME = "$(TARGET_NAME)";
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
		{tests_debug_config_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nestling.NestlingTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				STRING_CATALOG_GENERATE_SYMBOLS = NO;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Nestling.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Nestling";
			}};
			name = Debug;
		}};
		{tests_release_config_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nestling.NestlingTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				STRING_CATALOG_GENERATE_SYMBOLS = NO;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Nestling.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Nestling";
			}};
			name = Release;
		}};
		{uitests_debug_config_uuid} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nestling.NestlingUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				STRING_CATALOG_GENERATE_SYMBOLS = NO;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = Nestling;
			}};
			name = Debug;
		}};
		{uitests_release_config_uuid} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nestling.NestlingUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				STRING_CATALOG_GENERATE_SYMBOLS = NO;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = Nestling;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_config_list_uuid} /* Build configuration list for PBXProject "Nestling" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{project_debug_config_uuid} /* Debug */,
				{project_release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_config_list_uuid} /* Build configuration list for PBXNativeTarget "Nestling" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{target_debug_config_uuid} /* Debug */,
				{target_release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{tests_config_list_uuid} /* Build configuration list for PBXNativeTarget "NestlingTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{tests_debug_config_uuid} /* Debug */,
				{tests_release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{uitests_config_list_uuid} /* Build configuration list for PBXNativeTarget "NestlingUITests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{uitests_debug_config_uuid} /* Debug */,
				{uitests_release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}
'''
print(project_content)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo "✅ project.pbxproj generated"
else
    echo "❌ Failed to generate project.pbxproj"
    exit 1
fi

# Step 7: Restore Assets if they exist
echo ""
echo "7️⃣  Restoring assets..."
if [ -d "$SOURCE_BACKUP/Assets.xcassets" ]; then
    mkdir -p "Nestling.xcodeproj"
    cp -R "$SOURCE_BACKUP/Assets.xcassets" "Nestling.xcodeproj/" 2>/dev/null || true
    echo "✅ Assets restored"
else
    echo "ℹ️  No assets to restore"
fi

# Step 8: Instructions for adding files in Xcode
echo ""
echo "=========================="
echo "✅ Project regenerated!"
echo ""
echo "📝 IMPORTANT NEXT STEPS:"
echo ""
echo "1. Open the project in Xcode:"
echo "   open $NESTLING_DIR/Nestling.xcodeproj"
echo ""
echo "2. In Xcode, add all source files:"
echo "   - Right-click 'Nestling' folder in Project Navigator"
echo "   - Select 'Add Files to Nestling...'"
echo "   - Navigate to: $NESTLING_DIR/Nestling"
echo "   - Select all folders (App, Design, Domain, Features, Services, Utilities)"
echo "   - Ensure 'Create groups' is selected"
echo "   - Ensure 'Add to targets: Nestling' is checked"
echo "   - Click 'Add'"
echo ""
echo "3. Add test files similarly:"
echo "   - Right-click 'NestlingTests' folder"
echo "   - Add files from: $NESTLING_DIR/NestlingTests"
echo "   - Ensure 'Add to targets: NestlingTests' is checked"
echo ""
echo "4. Build the project (⌘B) to verify everything works"
echo ""
echo "💾 Backup saved at: $BACKUP_DIR"
echo ""

