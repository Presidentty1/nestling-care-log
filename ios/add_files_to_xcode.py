#!/usr/bin/env python3
"""
Script to add new Swift files to Xcode project.pbxproj file.
Adds InitialStateView.swift, GuidanceStripView.swift, and ExampleDataBanner.swift
"""

import re
import random
import string
import sys

def gen_xcode_id():
    """Generate Xcode-style 24-character hex ID"""
    return ''.join(random.choices(string.hexdigits.upper(), k=24))

def add_files_to_xcode_project(project_path):
    """Add the three new Swift files to the Xcode project"""
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Generate unique IDs for each file
    initial_state_file_id = gen_xcode_id()
    guidance_strip_file_id = gen_xcode_id()
    example_banner_file_id = gen_xcode_id()
    
    initial_state_build_id = gen_xcode_id()
    guidance_strip_build_id = gen_xcode_id()
    example_banner_build_id = gen_xcode_id()
    
    print(f"Generated IDs:")
    print(f"  InitialStateView: file={initial_state_file_id}, build={initial_state_build_id}")
    print(f"  GuidanceStripView: file={guidance_strip_file_id}, build={guidance_strip_build_id}")
    print(f"  ExampleDataBanner: file={example_banner_file_id}, build={example_banner_build_id}")
    
    # 1. Add to PBXBuildFile section (after NotificationsIntroView)
    build_file_entry = f'\t\t{initial_state_build_id} /* InitialStateView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {initial_state_file_id} /* InitialStateView.swift */; }};\n\t\t{guidance_strip_build_id} /* GuidanceStripView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {guidance_strip_file_id} /* GuidanceStripView.swift */; }};\n\t\t{example_banner_build_id} /* ExampleDataBanner.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {example_banner_file_id} /* ExampleDataBanner.swift */; }};\n'
    
    if '0BF6AFE3DCA196BC0253CC6C /* NotificationsIntroView.swift in Sources */' in content:
        content = content.replace(
            '\t\t0BF6AFE3DCA196BC0253CC6C /* NotificationsIntroView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 095C2B393ACD67C250C69417 /* NotificationsIntroView.swift */; };\n',
            '\t\t0BF6AFE3DCA196BC0253CC6C /* NotificationsIntroView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 095C2B393ACD67C250C69417 /* NotificationsIntroView.swift */; };\n' + build_file_entry
        )
    else:
        # Fallback: add after first PBXBuildFile entry
        match = re.search(r'(/\* Begin PBXBuildFile section \*/\n\t\t[^\n]+\n)', content)
        if match:
            content = content[:match.end()] + build_file_entry + content[match.end():]
    
    # 2. Add to PBXFileReference section (after OnboardingView)
    file_ref_entry = f'\t\t{initial_state_file_id} /* InitialStateView.swift */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = InitialStateView.swift; sourceTree = "<group>"; }};\n\t\t{guidance_strip_file_id} /* GuidanceStripView.swift */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = GuidanceStripView.swift; sourceTree = "<group>"; }};\n\t\t{example_banner_file_id} /* ExampleDataBanner.swift */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = ExampleDataBanner.swift; sourceTree = "<group>"; }};\n'
    
    if '4C27114EF63E6EDD373947B8 /* OnboardingView.swift */' in content:
        content = content.replace(
            '\t\t4C27114EF63E6EDD373947B8 /* OnboardingView.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = OnboardingView.swift; sourceTree = "<group>"; };\n',
            '\t\t4C27114EF63E6EDD373947B8 /* OnboardingView.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = OnboardingView.swift; sourceTree = "<group>"; };\n' + file_ref_entry
        )
    
    # 3. Add to Onboarding group (EE2ED02971DFD6F69CF8DA4E) - add InitialStateView after OnboardingView
    if '4C27114EF63E6EDD373947B8 /* OnboardingView.swift */,' in content:
        content = content.replace(
            '\t\t\t\t4C27114EF63E6EDD373947B8 /* OnboardingView.swift */,\n',
            '\t\t\t\t4C27114EF63E6EDD373947B8 /* OnboardingView.swift */,\n\t\t\t\t' + initial_state_file_id + ' /* InitialStateView.swift */,\n'
        )
    
    # 4. Add to Home group (1CC7CC6A3451AADD81EC4356) - add after HomeView
    if '6986225EDDDD8DE7B108BFB0 /* HomeView.swift */,' in content:
        content = content.replace(
            '\t\t\t\t6986225EDDDD8DE7B108BFB0 /* HomeView.swift */,\n',
            '\t\t\t\t6986225EDDDD8DE7B108BFB0 /* HomeView.swift */,\n\t\t\t\t' + guidance_strip_file_id + ' /* GuidanceStripView.swift */,\n\t\t\t\t' + example_banner_file_id + ' /* ExampleDataBanner.swift */,\n'
        )
    
    # 5. Add to PBXSourcesBuildPhase - add InitialStateView after OnboardingView
    if 'ACD833A00AE9975154A5972C /* OnboardingView.swift in Sources */,' in content:
        content = content.replace(
            '\t\t\t\tACD833A00AE9975154A5972C /* OnboardingView.swift in Sources */,\n',
            '\t\t\t\tACD833A00AE9975154A5972C /* OnboardingView.swift in Sources */,\n\t\t\t\t' + initial_state_build_id + ' /* InitialStateView.swift in Sources */,\n'
        )
    
    # 6. Add GuidanceStripView and ExampleDataBanner after HomeView in Sources
    if 'C9F98796439E3460DA497C75 /* HomeView.swift in Sources */,' in content:
        content = content.replace(
            '\t\t\t\tC9F98796439E3460DA497C75 /* HomeView.swift in Sources */,\n',
            '\t\t\t\tC9F98796439E3460DA497C75 /* HomeView.swift in Sources */,\n\t\t\t\t' + guidance_strip_build_id + ' /* GuidanceStripView.swift in Sources */,\n\t\t\t\t' + example_banner_build_id + ' /* ExampleDataBanner.swift in Sources */,\n'
        )
    
    # Write back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"\n✅ Successfully added files to Xcode project!")
    print(f"   - InitialStateView.swift")
    print(f"   - GuidanceStripView.swift")
    print(f"   - ExampleDataBanner.swift")
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
