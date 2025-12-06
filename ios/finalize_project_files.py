#!/usr/bin/env python3
"""
Script to add FirstLogView.swift and Localizable.strings to Xcode project.pbxproj file.
"""

import re
import random
import string
import sys
import os

def gen_xcode_id():
    """Generate Xcode-style 24-character hex ID"""
    return ''.join(random.choices(string.hexdigits.upper(), k=24))

def add_files_to_xcode_project(project_path):
    """Add FirstLogView.swift and Localizable.strings to the Xcode project"""
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Generate unique IDs
    first_log_file_id = gen_xcode_id()
    first_log_build_id = gen_xcode_id()
    
    strings_file_id = gen_xcode_id()
    strings_build_id = gen_xcode_id()
    
    print(f"Generated IDs:")
    print(f"  FirstLogView: file={first_log_file_id}, build={first_log_build_id}")
    print(f"  Localizable.strings: file={strings_file_id}, build={strings_build_id}")
    
    # 1. Add to PBXBuildFile section
    # FirstLogView (Sources)
    build_file_entry_src = f'\t\t{first_log_build_id} /* FirstLogView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {first_log_file_id} /* FirstLogView.swift */; }};\n'
    
    if '/* FirstLogView.swift in Sources */' not in content:
        # Try to find any Swift file in Sources to append after
        match = re.search(r'([0-9A-F]+ /\* [a-zA-Z0-9]+\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = [0-9A-F]+ /\* [a-zA-Z0-9]+\.swift \*/; \};\n)', content)
        if match:
            content = content.replace(match.group(1), match.group(1) + build_file_entry_src)
        else:
            # Fallback to beginning of section
            match = re.search(r'(/\* Begin PBXBuildFile section \*/\n\t\t[^\n]+\n)', content)
            if match:
                content = content[:match.end()] + build_file_entry_src + content[match.end():]
    
    # Localizable.strings (Resources)
    build_file_entry_res = f'\t\t{strings_build_id} /* Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {strings_file_id} /* Localizable.strings */; }};\n'
    
    if '/* Localizable.strings in Resources */' not in content:
        # Find existing resource or add to beginning
        if '/* Assets.xcassets in Resources */' in content:
            content = content.replace(
                '/* Assets.xcassets in Resources */ = {isa = PBXBuildFile;',
                '/* Assets.xcassets in Resources */ = {isa = PBXBuildFile;\n' + build_file_entry_res
            )
        else:
             match = re.search(r'(/\* Begin PBXBuildFile section \*/\n\t\t[^\n]+\n)', content)
             if match:
                 content = content[:match.end()] + build_file_entry_res + content[match.end():]

    
    # 2. Add to PBXFileReference section
    file_ref_entry_src = f'\t\t{first_log_file_id} /* FirstLogView.swift */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = FirstLogView.swift; sourceTree = "<group>"; }};\n'
    file_ref_entry_res = f'\t\t{strings_file_id} /* Localizable.strings */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = text.plist.strings; name = en; path = Resources/en.lproj/Localizable.strings; sourceTree = "<group>"; }};\n'
    
    if '/* FirstLogView.swift */' not in content:
        if '/* HomeView.swift */' in content:
            content = content.replace(
                '/* HomeView.swift */ = {isa = PBXFileReference;',
                '/* HomeView.swift */ = {isa = PBXFileReference;\n' + file_ref_entry_src
            )
        else:
             match = re.search(r'(/\* Begin PBXFileReference section \*/\n\t\t[^\n]+\n)', content)
             if match:
                 content = content[:match.end()] + file_ref_entry_src + content[match.end():]

    if '/* Localizable.strings */' not in content:
        if '/* Assets.xcassets */' in content:
            content = content.replace(
                '/* Assets.xcassets */ = {isa = PBXFileReference;',
                '/* Assets.xcassets */ = {isa = PBXFileReference;\n' + file_ref_entry_res
            )
        else:
             match = re.search(r'(/\* Begin PBXFileReference section \*/\n\t\t[^\n]+\n)', content)
             if match:
                 content = content[:match.end()] + file_ref_entry_res + content[match.end():]

    
    # 3. Add FirstLogView to Onboarding group
    # Try to find Onboarding group
    if '/* OnboardingView.swift */,' in content and '/* FirstLogView.swift */,' not in content:
        content = content.replace(
            '/* OnboardingView.swift */,',
            '/* OnboardingView.swift */,\n\t\t\t\t' + first_log_file_id + ' /* FirstLogView.swift */,'
        )
    elif '/* OnboardingView.swift */' in content and '/* FirstLogView.swift */,' not in content:
         # Fallback if comma is missing or formatting differs
         pass
    
    # 4. Add Localizable.strings to Resources group
    # We need to find the main group or a Resources group. 
    # Assuming a group containing Assets.xcassets exists
    if '/* Assets.xcassets */,' in content and '/* Localizable.strings */,' not in content:
        content = content.replace(
            '/* Assets.xcassets */,',
            '/* Assets.xcassets */,\n\t\t\t\t' + strings_file_id + ' /* Localizable.strings */,'
        )
    
    # 5. Add to PBXSourcesBuildPhase
    if '/* OnboardingView.swift in Sources */,' in content and '/* FirstLogView.swift in Sources */,' not in content:
        content = content.replace(
            '/* OnboardingView.swift in Sources */,',
            '/* OnboardingView.swift in Sources */,\n\t\t\t\t' + first_log_build_id + ' /* FirstLogView.swift in Sources */,'
        )
    
    # 6. Add to PBXResourcesBuildPhase
    if '/* Assets.xcassets in Resources */,' in content and '/* Localizable.strings in Resources */,' not in content:
        content = content.replace(
            '/* Assets.xcassets in Resources */,',
            '/* Assets.xcassets in Resources */,\n\t\t\t\t' + strings_build_id + ' /* Localizable.strings in Resources */,'
        )
    
    # Write back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"\n✅ Successfully added files to Xcode project!")
    print(f"   - FirstLogView.swift")
    print(f"   - Localizable.strings")
    return True

if __name__ == '__main__':
    project_path = '/Users/tyhorton/Coding Projects/nestling-care-log/ios/Nuzzle/Nestling.xcodeproj/project.pbxproj'
    try:
        add_files_to_xcode_project(project_path)
        print("\n✅ Done! Now clean and build in Xcode (Cmd+Shift+K, then Cmd+B)")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
