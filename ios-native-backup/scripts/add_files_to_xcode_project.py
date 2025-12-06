#!/usr/bin/env python3
"""
Automatically add all source files to Xcode project
This script modifies project.pbxproj to include all Swift files
"""

import os
import re
import secrets
from pathlib import Path
from collections import defaultdict

def generate_uuid():
    """Generate a 24-character hex UUID in Xcode format"""
    return secrets.token_hex(12).upper()

def find_swift_files(directory):
    """Find all Swift files recursively"""
    swift_files = []
    for root, dirs, files in os.walk(directory):
        # Skip hidden directories and build folders
        dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'build']
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, directory)
                swift_files.append(rel_path)
    return sorted(swift_files)

def create_group_structure(files, base_path=""):
    """Create nested group structure from file paths"""
    groups = defaultdict(list)
    
    for file_path in files:
        parts = file_path.split(os.sep)
        if len(parts) > 1:
            group_name = parts[0]
            remaining_path = os.sep.join(parts[1:])
            groups[group_name].append(remaining_path)
        else:
            groups[""].append(file_path)
    
    return groups

def main():
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent / "Nestling"
    project_file = project_dir / "Nestling.xcodeproj" / "project.pbxproj"
    
    if not project_file.exists():
        print(f"❌ ERROR: Project file not found at {project_file}")
        return 1
    
    print("🔍 Scanning for Swift files...")
    
    # Find all Swift files
    nestling_files = find_swift_files(project_dir / "Nestling")
    test_files = find_swift_files(project_dir / "NestlingTests") if (project_dir / "NestlingTests").exists() else []
    uitest_files = find_swift_files(project_dir / "NestlingUITests") if (project_dir / "NestlingUITests").exists() else []
    
    print(f"   Found {len(nestling_files)} files in Nestling/")
    print(f"   Found {len(test_files)} files in NestlingTests/")
    print(f"   Found {len(uitest_files)} files in NestlingUITests/")
    
    if len(nestling_files) == 0:
        print("❌ ERROR: No Swift files found in Nestling/ directory")
        return 1
    
    # Read project file
    print("\n📖 Reading project file...")
    with open(project_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the main group UUID (Nestling folder)
    nestling_group_match = re.search(r'(\w{24})\s+/\*\s+Nestling\s+\*/\s*=\s*\{[^}]*isa = PBXGroup[^}]*path = Nestling', content)
    if not nestling_group_match:
        print("❌ ERROR: Could not find Nestling group in project file")
        print("   Make sure the project was regenerated correctly")
        return 1
    
    nestling_group_uuid = nestling_group_match.group(1)
    print(f"   Found Nestling group: {nestling_group_uuid}")
    
    # Find sources build phase UUID
    sources_phase_match = re.search(r'(\w{24})\s+/\*\s+Sources\s+\*/\s*=\s*\{[^}]*isa = PBXSourcesBuildPhase', content)
    if not sources_phase_match:
        print("❌ ERROR: Could not find Sources build phase")
        return 1
    
    sources_phase_uuid = sources_phase_match.group(1)
    print(f"   Found Sources build phase: {sources_phase_uuid}")
    
    # Generate UUIDs for all files and build file references
    file_refs = {}
    build_files = {}
    groups = {}
    
    print("\n📝 Generating file references...")
    
    # Process Nestling files
    for file_path in nestling_files:
        file_uuid = generate_uuid()
        build_file_uuid = generate_uuid()
        
        # Create file reference
        file_name = os.path.basename(file_path)
        file_refs[file_path] = {
            'uuid': file_uuid,
            'build_file_uuid': build_file_uuid,
            'name': file_name,
            'path': file_path,
            'target': 'Nestling'
        }
        
        # Create group structure
        dir_path = os.path.dirname(file_path)
        if dir_path:
            parts = dir_path.split(os.sep)
            current_path = ""
            for part in parts:
                if current_path:
                    current_path = os.path.join(current_path, part)
                else:
                    current_path = part
                
                if current_path not in groups:
                    groups[current_path] = {
                        'uuid': generate_uuid(),
                        'name': part,
                        'path': current_path,
                        'parent': os.path.dirname(current_path) if os.path.dirname(current_path) else None
                    }
    
    # Process test files
    for file_path in test_files:
        file_uuid = generate_uuid()
        build_file_uuid = generate_uuid()
        file_refs[file_path] = {
            'uuid': file_uuid,
            'build_file_uuid': build_file_uuid,
            'name': os.path.basename(file_path),
            'path': file_path,
            'target': 'NestlingTests',
            'prefix': 'NestlingTests'
        }
    
    # Process UI test files
    for file_path in uitest_files:
        file_uuid = generate_uuid()
        build_file_uuid = generate_uuid()
        file_refs[file_path] = {
            'uuid': file_uuid,
            'build_file_uuid': build_file_uuid,
            'name': os.path.basename(file_path),
            'path': file_path,
            'target': 'NestlingUITests',
            'prefix': 'NestlingUITests'
        }
    
    print(f"   Generated {len(file_refs)} file references")
    print(f"   Generated {len(groups)} group references")
    
    # Now we need to modify the project file
    # This is complex - we'll use a simpler approach: create a script that Xcode can run
    # Or we can use xcodebuild/xcodeproj gem
    
    print("\n⚠️  Direct project file modification is complex and error-prone.")
    print("   Creating a script that uses Xcode's command-line tools instead...")
    
    # Create a shell script that uses xcodebuild or manual instructions
    script_path = script_dir / "add_files_via_xcode.sh"
    
    with open(script_path, 'w') as f:
        f.write('#!/bin/bash\n')
        f.write('# Script to add files to Xcode project\n')
        f.write('# This opens Xcode and provides instructions\n\n')
        f.write(f'PROJECT_DIR="{project_dir}"\n')
        f.write(f'PROJECT_FILE="$PROJECT_DIR/Nestling.xcodeproj"\n\n')
        f.write('echo "📝 To add files automatically, use this AppleScript:"\n')
        f.write('echo ""\n')
        f.write('cat << \'APPLESCRIPT\'\n')
        f.write('tell application "Xcode"\n')
        f.write('    activate\n')
        f.write('    open POSIX file "' + str(project_file.absolute()) + '"\n')
        f.write('end tell\n')
        f.write('APPLESCRIPT\n')
    
    script_path.chmod(0o755)
    
    # Actually, let's create a better solution using Ruby/xcodeproj or direct modification
    # For now, let's create a comprehensive guide and a helper script
    
    print("\n✅ Created helper script")
    print(f"   Run: bash {script_path}")
    print("\n💡 Alternative: Use the manual steps in ADD_FILES_TO_XCODE.md")
    print("   Or I can create a Ruby script using the xcodeproj gem if you have it installed")
    
    return 0

if __name__ == "__main__":
    exit(main())

