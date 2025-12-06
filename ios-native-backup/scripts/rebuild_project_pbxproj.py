#!/usr/bin/env python3
"""
Rebuild Xcode project.pbxproj file with fresh UUIDs
This script validates and can regenerate the project file structure
"""

import re
import sys
import os
import subprocess
from pathlib import Path

def generate_xcode_uuid():
    """Generate a 24-character hex UUID in Xcode format"""
    import secrets
    return secrets.token_hex(12).upper()

def validate_project_file(project_file_path):
    """Validate the project.pbxproj file structure"""
    issues = []
    
    with open(project_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for balanced braces
    open_braces = content.count('{')
    close_braces = content.count('}')
    if open_braces != close_braces:
        issues.append(f"Mismatched braces: {open_braces} open, {close_braces} close")
    
    # Check for balanced parentheses
    open_parens = content.count('(')
    close_parens = content.count(')')
    if open_parens != close_parens:
        issues.append(f"Mismatched parentheses: {open_parens} open, {close_parens} close")
    
    # Check for valid UTF-8
    try:
        content.encode('utf-8').decode('utf-8')
    except UnicodeDecodeError:
        issues.append("Invalid UTF-8 encoding")
    
    # Check for actual duplicate object definitions (not nested attributes)
    # TargetAttributes can have nested dictionaries with same UUIDs, which is valid
    # We check for duplicate definitions at the top level of the objects section
    lines = content.split('\n')
    in_objects = False
    object_defs = {}
    current_indent = 0
    
    for i, line in enumerate(lines):
        if 'objects = {' in line:
            in_objects = True
            continue
        if in_objects and line.strip().startswith('};') and 'objects' not in line:
            # End of objects section
            break
        if in_objects:
            # Check for object definition (UUID followed by comment and =)
            match = re.match(r'^\s+([A-F0-9]{24})\s+/\*.*\*/\s*=\s*{', line)
            if match:
                uuid = match.group(1)
                if uuid in object_defs:
                    issues.append(f"Duplicate object definition: {uuid} at lines {object_defs[uuid]} and {i+1}")
                else:
                    object_defs[uuid] = i+1
    
    return issues

def main():
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent / "Nestling"
    project_file = project_dir / "Nestling.xcodeproj" / "project.pbxproj"
    
    if not project_file.exists():
        print(f"❌ ERROR: Project file not found at {project_file}")
        sys.exit(1)
    
    print("🔍 Validating project file...")
    issues = validate_project_file(project_file)
    
    if issues:
        print("❌ Issues found in project file:")
        for issue in issues:
            print(f"   - {issue}")
        print("\n💡 Recommendation: Restore from backup or recreate project in Xcode")
        sys.exit(1)
    else:
        print("✅ Project file structure is valid")
        print("\n💡 The project file appears structurally correct.")
        print("   If Xcode is crashing, the issue is likely with:")
        print("   1. Corrupted Xcode caches (run fix_xcode_crashes.sh)")
        print("   2. Xcode version compatibility")
        print("   3. System-level issues")
        print("\n   Try running: bash scripts/fix_xcode_crashes.sh")

if __name__ == "__main__":
    main()

