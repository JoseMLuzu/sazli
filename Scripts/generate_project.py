#!/usr/bin/env python3
"""Regenerate the dependency-free Xcode project after adding or removing files."""
from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parent.parent
objects = []


def uid(value):
    return hashlib.sha1(value.encode()).hexdigest()[:24].upper()


def add(key, value):
    objects.append(f'{uid(key)} = {{ {value} }};')
    return uid(key)


def array(values):
    return '(' + ', '.join(values) + (',)' if values else ')')


def file(path, kind):
    return add(path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = "{path}"; sourceTree = SOURCE_ROOT;')


def phase(name, kind, files):
    builds = [add(name + p, f'isa = PBXBuildFile; fileRef = {uid(p)};') for p in files]
    return add(name, f'isa = {kind}; buildActionMask = 2147483647; files = {array(builds)}; runOnlyForDeploymentPostprocessing = 0;')


def configs(name, settings):
    refs = []
    for mode in ('Debug', 'Release'):
        mode_settings = settings + (' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG_INFORMATION_FORMAT = dwarf;' if mode == 'Debug' else ' SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
        if mode == 'Debug':
            mode_settings += ' SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; ENABLE_TESTABILITY = YES;'
        refs.append(add(name + mode, f'isa = XCBuildConfiguration; buildSettings = {{ {mode_settings} }}; name = {mode};'))
    return add(name + 'Configurations', f'isa = XCConfigurationList; buildConfigurations = {array(refs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')


sources = sorted(str(p.relative_to(ROOT)) for p in (ROOT / 'Sazli').rglob('*.swift'))
tests = sorted(str(p.relative_to(ROOT)) for p in (ROOT / 'SazliTests').rglob('*.swift'))
resources = ['Sazli/Resources/Assets.xcassets', 'Sazli/Resources/PrivacyInfo.xcprivacy']
for path in sources + tests:
    file(path, 'sourcecode.swift')
file(resources[0], 'folder.assetcatalog')
file(resources[1], 'text.xml')
app = add('app', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = Sazli.app; sourceTree = BUILT_PRODUCTS_DIR;')
test_product = add('testProduct', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = SazliTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
products = add('products', f'isa = PBXGroup; children = {array([app, test_product])}; name = Products; sourceTree = "<group>";')
source_group = add('sourceGroup', f'isa = PBXGroup; children = {array([uid(p) for p in sources + resources])}; name = Sazli; sourceTree = "<group>";')
test_group = add('testGroup', f'isa = PBXGroup; children = {array([uid(p) for p in tests])}; name = SazliTests; sourceTree = "<group>";')
main_group = add('main', f'isa = PBXGroup; children = {array([source_group, test_group, products])}; sourceTree = "<group>";')
project_configs = configs('project', 'IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; SWIFT_VERSION = 6.0; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; ENABLE_USER_SCRIPT_SANDBOXING = YES;')
app_configs = configs('target', 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; PRODUCT_BUNDLE_IDENTIFIER = com.sazli.app; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = Sazli; INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.food-and-drink"; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; MARKETING_VERSION = 1.0; CURRENT_PROJECT_VERSION = 1; CODE_SIGN_STYLE = Automatic; SWIFT_EMIT_LOC_STRINGS = YES; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";')
test_configs = configs('tests', 'PRODUCT_BUNDLE_IDENTIFIER = com.sazli.app.tests; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; GENERATE_INFOPLIST_FILE = YES; CODE_SIGN_STYLE = Automatic; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Sazli.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Sazli"; BUNDLE_LOADER = "$(TEST_HOST)"; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks";')
app_phases = [phase('sources', 'PBXSourcesBuildPhase', sources), phase('resources', 'PBXResourcesBuildPhase', resources), phase('frameworks', 'PBXFrameworksBuildPhase', [])]
test_phases = [phase('testSources', 'PBXSourcesBuildPhase', tests), phase('testFrameworks', 'PBXFrameworksBuildPhase', [])]
add('appTarget', f'isa = PBXNativeTarget; buildConfigurationList = {app_configs}; buildPhases = {array(app_phases)}; buildRules = (); dependencies = (); name = Sazli; productName = Sazli; productReference = {app}; productType = "com.apple.product-type.application";')
proxy = add('proxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("appTarget")}; remoteInfo = Sazli;')
dependency = add('dependency', f'isa = PBXTargetDependency; target = {uid("appTarget")}; targetProxy = {proxy};')
add('testTarget', f'isa = PBXNativeTarget; buildConfigurationList = {test_configs}; buildPhases = {array(test_phases)}; buildRules = (); dependencies = {array([dependency])}; name = SazliTests; productName = SazliTests; productReference = {test_product}; productType = "com.apple.product-type.bundle.unit-test";')
add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1700; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; knownRegions = (en, Base); mainGroup = {main_group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {array([uid("appTarget"), uid("testTarget")])};')
project = ROOT / 'Sazli.xcodeproj'
project.mkdir(exist_ok=True)
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(objects) + f'\n}}; rootObject = {uid("project")}; }}\n')
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)


def reference(target, name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(target)}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:Sazli.xcodeproj"/>'


app_ref = reference('appTarget', 'Sazli.app')
test_ref = reference('testTarget', 'SazliTests.xctest')
(schemes / 'Sazli.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1700" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
    <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
  </BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(f'Generated {project.name}: {len(sources)} app files and {len(tests)} test files.')
