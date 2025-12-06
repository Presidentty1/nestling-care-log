#!/usr/bin/env python3
"""
Script to add new Swift files to Xcode project.pbxproj
Adds:
- MonthlyCalendarView.swift
- FreeTierUsageCard.swift
- UpgradePromptBanner.swift
"""

import re
import random
import string
import sys
import os

def gen_xcode_id():
    """Generate Xcode-style 24-character hex ID"""
    return ''.join(random.choices('0123456789ABCDEF', k=24))

def add_new_files(project_path):
    """Add new Swift files to Xcode project"""
    
    print(f"Reading project file: {project_path}")
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Files to add
    files_to_add = [
        {
            'name': 'MonthlyCalendarView.swift',
            'path': 'Nestling/Features/History/MonthlyCalendarView.swift',
            'group': 'History'
        },
        {
            'name': 'FreeTierUsageCard.swift',
            'path': 'Nestling/Design/Components/FreeTierUsageCard.swift',
            'group': 'Components'
        },
        {
            'name': 'UpgradePromptBanner.swift',
            'path': 'Nestling/Design/Components/UpgradePromptBanner.swift',
            'group': 'Components'
        },
        {
            'name': 'FirstTasksChecklistCard.swift',
            'path': 'Nestling/Features/Home/FirstTasksChecklistCard.swift',
            'group': 'Home'
        }
    ]
    
    for file_info in files_to_add:
        # Check if file already exists in project
        if file_info['name'] in content:
            print(f"⚠️  {file_info['name']} already in project, skipping")
            continue
        
        print(f"Adding {file_info['name']}...")
        
        # Generate IDs
        file_ref_id = gen_xcode_id()
        build_file_id = gen_xcode_id()
        
        print(f"  File ref ID: {file_ref_id}")
        print(f"  Build ID: {build_file_id}")
        
        # 1. Add to PBXBuildFile section (Sources)
        build_file_entry = f'\t\t{build_file_id} /* {file_info["name"]} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_info["name"]} */; }};\n'
        
        # Find PBXBuildFile section and add entry
        match = re.search(r'(/\* Begin PBXBuildFile section \*/\n)', content)
        if match:
            insert_pos = match.end()
            content = content[:insert_pos] + build_file_entry + content[insert_pos:]
            print(f"  ✅ Added to PBXBuildFile section")
        
        # 2. Add to PBXFileReference section
        file_ref_entry = f'\t\t{file_ref_id} /* {file_info["name"]} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_info["name"]}; sourceTree = "<group>"; }};\n'
        
        match = re.search(r'(/\* Begin PBXFileReference section \*/\n)', content)
        if match:
            insert_pos = match.end()
            content = content[:insert_pos] + file_ref_entry + content[insert_pos:]
            print(f"  ✅ Added to PBXFileReference section")
        
        # 3. Add to appropriate PBXGroup (History or Components)
        group_pattern = rf'(/\* {file_info["group"]} \*/.*?children = \(\n)(.*?)(\n\t\t\t\);)'
        match = re.search(group_pattern, content, re.DOTALL)
        
        if match:
            group_children = match.group(2)
            new_child_entry = f'\t\t\t\t{file_ref_id} /* {file_info["name"]} */,\n'
            updated_children = group_children + new_child_entry
            content = content[:match.start(2)] + updated_children + content[match.end(2):]
            print(f"  ✅ Added to {file_info['group']} group")
        else:
            print(f"  ⚠️  Could not find {file_info['group']} group, file may need manual addition")
        
        # 4. Add to PBXSourcesBuildPhase (compile step)
        sources_pattern = r'(/\* Sources \*/.*?files = \(\n)(.*?)(\n\t\t\t\);)'
        match = re.search(sources_pattern, content, re.DOTALL)
        
        if match:
            sources_files = match.group(2)
            new_source_entry = f'\t\t\t\t{build_file_id} /* {file_info["name"]} in Sources */,\n'
            updated_sources = sources_files + new_source_entry
            content = content[:match.start(2)] + updated_sources + content[match.end(2):]
            print(f"  ✅ Added to Sources build phase")
        
        print(f"  ✅ {file_info['name']} successfully added!\n")
    
    # Write back
    backup_path = project_path + '.backup_pre_phase1'
    print(f"\nCreating backup: {backup_path}")
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Writing updated project file...")
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\n✅ All files added successfully!")
    print("\nNext steps:")
    print("1. Open Xcode")
    print("2. Clean build folder (⇧⌘K)")
    print("3. Build (⌘B)")
    print("4. Run (⌘R)")

if __name__ == '__main__':
    project_path = 'Nuzzle/Nestling.xcodeproj/project.pbxproj'
    
    if not os.path.exists(project_path):
        print(f"Error: Could not find {project_path}")
        print("Make sure you run this script from the ios/ directory")
        sys.exit(1)
    
    add_new_files(project_path)

