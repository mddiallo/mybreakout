#!/usr/bin/env python3
"""Generates Prismabrique.xcodeproj/project.pbxproj from the current contents of the
Prismabrique/ and PrismabriqueTests/ directories.

This project was authored outside of Xcode (no macOS/Xcode available in this environment),
so the project file is generated programmatically instead of by hand to minimize the risk
of a malformed pbxproj. Re-run this script after adding/removing/renaming any source or
resource file so the project stays in sync with the file system.

Usage: python3 scripts/generate_xcodeproj.py
"""
import os
import uuid

ROOT = os.path.join(os.path.dirname(__file__), "..")
APP_DIR = os.path.join(ROOT, "Prismabrique")
TESTS_DIR = os.path.join(ROOT, "PrismabriqueTests")
PBXPROJ_PATH = os.path.join(ROOT, "Prismabrique.xcodeproj", "project.pbxproj")

BUNDLE_ID = "com.prismabrique.app"
DEPLOYMENT_TARGET = "26.0"
SWIFT_VERSION = "6.0"
MARKETING_VERSION = "1.0.0"

_ids = {}


def uid(key):
    """Stable, deterministic 24-hex-char pbxproj object ID per logical key."""
    if key not in _ids:
        h = uuid.uuid5(uuid.NAMESPACE_DNS, key).hex.upper()
        _ids[key] = h[:24]
    return _ids[key]


# ---------------------------------------------------------------------------
# App target: Swift sources (grouped) + resources
# ---------------------------------------------------------------------------
APP_GROUPS = {
    "Prismabrique": ["PrismabriqueApp.swift"],
    "Prismabrique/Models": [
        "Models/AppState.swift",
        "Models/BrickPattern.swift",
        "Models/GameBalanceConfig.swift",
        "Models/HemisphereRegion.swift",
        "Models/LevelConfig.swift",
        "Models/PlayerProgress.swift",
    ],
    "Prismabrique/Managers": [
        "Managers/AudioEngineManager.swift",
        "Managers/HapticsManager.swift",
        "Managers/LocationOptInManager.swift",
    ],
    "Prismabrique/Game": [
        "Game/GameEngine.swift",
        "Game/GameEntities.swift",
    ],
    "Prismabrique/Views": [
        "Views/ContentView.swift",
        "Views/GameView.swift",
        "Views/LevelSelectView.swift",
        "Views/LocationOptInSheetView.swift",
        "Views/MainMenuView.swift",
        "Views/Overlays.swift",
        "Views/SettingsView.swift",
    ],
    "Prismabrique/Views/Components": [
        "Views/Components/NeonButtonStyle.swift",
        "Views/Components/ScoreHUD.swift",
    ],
}

APP_RESOURCES = [
    "Resources/GameBalance.json",
    "PrivacyInfo.xcprivacy",
]

TEST_SOURCES = [
    "GameEngineTests.swift",
    "HemisphereRegionTests.swift",
    "LevelGeneratorTests.swift",
    "PersistenceStoreTests.swift",
]

file_type_by_ext = {
    ".swift": "sourcecode.swift",
    ".json": "text.json",
    ".xcprivacy": "text.xml",
}


class Ctx:
    def __init__(self):
        self.file_refs = []          # (uid, name, path, sourceTree, fileType, explicitType)
        self.build_files_sources = []  # (uid, fileRefUid, target)
        self.build_files_resources = []
        self.group_children = {}     # groupUid -> [childUid...]
        self.group_names = {}        # groupUid -> (name, path or None)


ctx = Ctx()


def add_file(rel_path, base_dir_key):
    """Registers a file reference for a project-relative path; returns its uid."""
    key = f"fileref::{base_dir_key}::{rel_path}"
    fid = uid(key)
    name = os.path.basename(rel_path)
    ext = os.path.splitext(name)[1]
    ftype = file_type_by_ext.get(ext, "text")
    ctx.file_refs.append((fid, name, rel_path, ftype))
    return fid


def add_group(name, path, children_uids, key=None):
    # NOTE: file references already carry their full path relative to the project root
    # (e.g. "Prismabrique/Models/AppState.swift"), so groups intentionally omit their own
    # "path" attribute -- otherwise Xcode would concatenate group path + file path and
    # produce a doubled, non-existent path like "Prismabrique/Models/Prismabrique/Models/...".
    gid = uid(key or f"group::{path or name}")
    ctx.group_children[gid] = children_uids
    ctx.group_names[gid] = (name, None)
    return gid


def build_app_groups_and_sources():
    sources_build_uids = []
    # Build subgroups bottom-up. Each group key is its path from Prismabrique/.
    group_uid_by_path = {}

    # Leaf file groups first
    for group_path, files in APP_GROUPS.items():
        child_uids = []
        for rel in files:
            full_rel = os.path.join("Prismabrique", rel)
            fid = add_file(full_rel, "app")
            child_uids.append(fid)
            bf_uid = uid(f"buildfile::sources::{full_rel}")
            ctx.build_files_sources.append((bf_uid, fid))
            sources_build_uids.append(bf_uid)
        folder_name = os.path.basename(group_path)
        group_uid_by_path[group_path] = (folder_name, child_uids)

    # Resource files (top-level of Prismabrique group, plus Resources subgroup)
    resource_build_uids = []
    game_balance_fid = add_file("Prismabrique/Resources/GameBalance.json", "app")
    bf = uid("buildfile::resources::GameBalance.json")
    ctx.build_files_resources.append((bf, game_balance_fid))
    resource_build_uids.append(bf)
    resources_group_uid = add_group("Resources", "Resources", [game_balance_fid], key="group::Prismabrique/Resources")

    privacy_fid = add_file("Prismabrique/PrivacyInfo.xcprivacy", "app")
    bf = uid("buildfile::resources::PrivacyInfo.xcprivacy")
    ctx.build_files_resources.append((bf, privacy_fid))
    resource_build_uids.append(bf)

    # Assets.xcassets as a single "folder.assetcatalog" file reference (Xcode treats the
    # whole .xcassets bundle as one reference, not individual children).
    assets_fid = uid("fileref::app::Prismabrique/Assets.xcassets")
    ctx.file_refs.append((assets_fid, "Assets.xcassets", "Prismabrique/Assets.xcassets", "folder.assetcatalog"))
    bf = uid("buildfile::resources::Assets.xcassets")
    ctx.build_files_resources.append((bf, assets_fid))
    resource_build_uids.append(bf)

    # Components subgroup nested inside Views group
    components_name, components_children = group_uid_by_path["Prismabrique/Views/Components"]
    components_gid = add_group(components_name, "Components", components_children, key="group::Prismabrique/Views/Components")

    views_name, views_children = group_uid_by_path["Prismabrique/Views"]
    views_gid = add_group(views_name, "Views", views_children + [components_gid], key="group::Prismabrique/Views")

    models_name, models_children = group_uid_by_path["Prismabrique/Models"]
    models_gid = add_group(models_name, "Models", models_children, key="group::Prismabrique/Models")

    managers_name, managers_children = group_uid_by_path["Prismabrique/Managers"]
    managers_gid = add_group(managers_name, "Managers", managers_children, key="group::Prismabrique/Managers")

    game_name, game_children = group_uid_by_path["Prismabrique/Game"]
    game_gid = add_group(game_name, "Game", game_children, key="group::Prismabrique/Game")

    root_app_children = list(group_uid_by_path["Prismabrique"][1])
    root_app_children += [models_gid, managers_gid, game_gid, views_gid, resources_group_uid, privacy_fid, assets_fid]
    root_group_uid = add_group("Prismabrique", "Prismabrique", root_app_children, key="group::Prismabrique")

    return root_group_uid, sources_build_uids, resource_build_uids


def build_tests_group_and_sources():
    child_uids = []
    build_uids = []
    for rel in TEST_SOURCES:
        full_rel = os.path.join("PrismabriqueTests", rel)
        fid = add_file(full_rel, "tests")
        child_uids.append(fid)
        bf_uid = uid(f"buildfile::sources::{full_rel}")
        ctx.build_files_sources.append((bf_uid, fid))
        build_uids.append(bf_uid)
    gid = add_group("PrismabriqueTests", "PrismabriqueTests", child_uids, key="group::PrismabriqueTests")
    return gid, build_uids


app_root_group, app_sources_build_uids, app_resources_build_uids = build_app_groups_and_sources()
tests_group, tests_sources_build_uids = build_tests_group_and_sources()

PROJECT_UID = uid("project")
MAIN_GROUP_UID = uid("mainGroup")
PRODUCTS_GROUP_UID = uid("productsGroup")
APP_PRODUCT_UID = uid("product::app")
TESTS_PRODUCT_UID = uid("product::tests")

APP_TARGET_UID = uid("target::app")
TESTS_TARGET_UID = uid("target::tests")

APP_SOURCES_PHASE_UID = uid("phase::app::sources")
APP_RESOURCES_PHASE_UID = uid("phase::app::resources")
APP_FRAMEWORKS_PHASE_UID = uid("phase::app::frameworks")
TESTS_SOURCES_PHASE_UID = uid("phase::tests::sources")
TESTS_RESOURCES_PHASE_UID = uid("phase::tests::resources")
TESTS_FRAMEWORKS_PHASE_UID = uid("phase::tests::frameworks")

TEST_DEPENDENCY_UID = uid("targetDependency::testsOnApp")
TEST_PROXY_UID = uid("containerProxy::testsOnApp")

PROJECT_CONFIG_LIST_UID = uid("configList::project")
APP_CONFIG_LIST_UID = uid("configList::app")
TESTS_CONFIG_LIST_UID = uid("configList::tests")

PROJECT_DEBUG_UID = uid("config::project::debug")
PROJECT_RELEASE_UID = uid("config::project::release")
APP_DEBUG_UID = uid("config::app::debug")
APP_RELEASE_UID = uid("config::app::release")
TESTS_DEBUG_UID = uid("config::tests::debug")
TESTS_RELEASE_UID = uid("config::tests::release")


def pbx_file_reference_lines():
    lines = []
    for (fid, name, rel_path, ftype) in ctx.file_refs:
        explicit = ""
        last_known = f"lastKnownFileType = {ftype}; "
        if ftype == "folder.assetcatalog":
            last_known = "lastKnownFileType = folder.assetcatalog; "
        lines.append(
            f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; {last_known}name = "{name}"; path = "{rel_path}"; sourceTree = "<group>"; }};'
        )
    return lines


def pbx_build_file_lines():
    lines = []
    name_by_fid = {fid: name for (fid, name, _p, _t) in ctx.file_refs}
    for (bf_uid, fid) in ctx.build_files_sources:
        lines.append(f'\t\t{bf_uid} /* {name_by_fid[fid]} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name_by_fid[fid]} */; }};')
    for (bf_uid, fid) in ctx.build_files_resources:
        lines.append(f'\t\t{bf_uid} /* {name_by_fid[fid]} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name_by_fid[fid]} */; }};')
    return lines


def pbx_group_lines():
    lines = []
    for gid, children in ctx.group_children.items():
        name, path = ctx.group_names[gid]
        child_lines = "\n".join(f'\t\t\t\t{c},' for c in children)
        path_attr = f'path = "{path}"; ' if path else ""
        lines.append(
            f'\t\t{gid} /* {name} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{child_lines}\n\t\t\t);\n\t\t\t{path_attr}name = "{name}";\n\t\t\tsourceTree = "<group>";\n\t\t}};'
        )
    return lines


def indent_list(uids, n=4):
    pad = "\t" * n
    return "\n".join(f'{pad}{u},' for u in uids)


file_refs_block = "\n".join(pbx_file_reference_lines())
build_files_block = "\n".join(pbx_build_file_lines())
groups_block = "\n".join(pbx_group_lines())

pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 77;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_files_block}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
\t\t{TEST_PROXY_UID} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {PROJECT_UID} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {APP_TARGET_UID};
\t\t\tremoteInfo = Prismabrique;
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
\t\t{APP_PRODUCT_UID} /* Prismabrique.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "Prismabrique.app"; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{TESTS_PRODUCT_UID} /* PrismabriqueTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = "PrismabriqueTests.xctest"; sourceTree = BUILT_PRODUCTS_DIR; }};
{file_refs_block}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{APP_FRAMEWORKS_PHASE_UID} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{TESTS_FRAMEWORKS_PHASE_UID} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{MAIN_GROUP_UID} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_root_group},
\t\t\t\t{tests_group},
\t\t\t\t{PRODUCTS_GROUP_UID},
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{PRODUCTS_GROUP_UID} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{APP_PRODUCT_UID} /* Prismabrique.app */,
\t\t\t\t{TESTS_PRODUCT_UID} /* PrismabriqueTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
{groups_block}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{APP_TARGET_UID} /* Prismabrique */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {APP_CONFIG_LIST_UID} /* Build configuration list for PBXNativeTarget "Prismabrique" */;
\t\t\tbuildPhases = (
\t\t\t\t{APP_SOURCES_PHASE_UID} /* Sources */,
\t\t\t\t{APP_FRAMEWORKS_PHASE_UID} /* Frameworks */,
\t\t\t\t{APP_RESOURCES_PHASE_UID} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = Prismabrique;
\t\t\tproductName = Prismabrique;
\t\t\tproductReference = {APP_PRODUCT_UID} /* Prismabrique.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{TESTS_TARGET_UID} /* PrismabriqueTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {TESTS_CONFIG_LIST_UID} /* Build configuration list for PBXNativeTarget "PrismabriqueTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{TESTS_SOURCES_PHASE_UID} /* Sources */,
\t\t\t\t{TESTS_FRAMEWORKS_PHASE_UID} /* Frameworks */,
\t\t\t\t{TESTS_RESOURCES_PHASE_UID} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{TEST_DEPENDENCY_UID} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = PrismabriqueTests;
\t\t\tproductName = PrismabriqueTests;
\t\t\tproductReference = {TESTS_PRODUCT_UID} /* PrismabriqueTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{PROJECT_UID} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{APP_TARGET_UID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t\t{TESTS_TARGET_UID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t\tTestTargetID = {APP_TARGET_UID};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST_UID} /* Build configuration list for PBXProject "Prismabrique" */;
\t\t\tcompatibilityVersion = "Xcode 15.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {MAIN_GROUP_UID};
\t\t\tproductRefGroup = {PRODUCTS_GROUP_UID} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{APP_TARGET_UID} /* Prismabrique */,
\t\t\t\t{TESTS_TARGET_UID} /* PrismabriqueTests */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{APP_RESOURCES_PHASE_UID} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{indent_list(app_resources_build_uids)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{TESTS_RESOURCES_PHASE_UID} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{APP_SOURCES_PHASE_UID} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{indent_list(app_sources_build_uids)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{TESTS_SOURCES_PHASE_UID} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{indent_list(tests_sources_build_uids)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{TEST_DEPENDENCY_UID} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {APP_TARGET_UID} /* Prismabrique */;
\t\t\ttargetProxy = {TEST_PROXY_UID} /* PBXContainerItemProxy */;
\t\t}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
\t\t{PROJECT_DEBUG_UID} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{PROJECT_RELEASE_UID} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{APP_DEBUG_UID} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = NO;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Prismabrique;
\t\t\t\tINFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.games";
\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Prismabrique can optionally use your approximate location, only after you opt in from Settings, to choose a cosmetic ambient color theme (for example, Northern or Southern hemisphere skies). This never affects gameplay, is never used while the app is in the background, and your exact location is never stored -- only a broad region name is saved on this device. You can disable this at any time in Settings.";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIStatusBarHidden = NO;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};
\t\t\t\tMARKETING_VERSION = {MARKETING_VERSION};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{APP_RELEASE_UID} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = NO;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Prismabrique;
\t\t\t\tINFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.games";
\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Prismabrique can optionally use your approximate location, only after you opt in from Settings, to choose a cosmetic ambient color theme (for example, Northern or Southern hemisphere skies). This never affects gameplay, is never used while the app is in the background, and your exact location is never stored -- only a broad region name is saved on this device. You can disable this at any time in Settings.";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIStatusBarHidden = NO;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};
\t\t\t\tMARKETING_VERSION = {MARKETING_VERSION};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{TESTS_DEBUG_UID} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};
\t\t\t\tMARKETING_VERSION = {MARKETING_VERSION};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}.tests";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Prismabrique.app/Prismabrique";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{TESTS_RELEASE_UID} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};
\t\t\t\tMARKETING_VERSION = {MARKETING_VERSION};
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}.tests";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Prismabrique.app/Prismabrique";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{PROJECT_CONFIG_LIST_UID} /* Build configuration list for PBXProject "Prismabrique" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{PROJECT_DEBUG_UID} /* Debug */,
\t\t\t\t{PROJECT_RELEASE_UID} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{APP_CONFIG_LIST_UID} /* Build configuration list for PBXNativeTarget "Prismabrique" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{APP_DEBUG_UID} /* Debug */,
\t\t\t\t{APP_RELEASE_UID} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{TESTS_CONFIG_LIST_UID} /* Build configuration list for PBXNativeTarget "PrismabriqueTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{TESTS_DEBUG_UID} /* Debug */,
\t\t\t\t{TESTS_RELEASE_UID} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {PROJECT_UID} /* Project object */;
}}
"""

os.makedirs(os.path.dirname(PBXPROJ_PATH), exist_ok=True)
with open(PBXPROJ_PATH, "w") as f:
    f.write(pbxproj)

print(f"Wrote {PBXPROJ_PATH} ({len(pbxproj)} bytes)")
print(f"App target UID: {APP_TARGET_UID}")
print(f"Files registered: {len(ctx.file_refs)} refs, {len(ctx.build_files_sources)} source build files, {len(ctx.build_files_resources)} resource build files")
