#!/usr/bin/env python3
"""Remove duplicate source file references from Xcode project."""

import re
import sys
import os

def remove_duplicate_sources(project_path):
    """Remove duplicate source file references."""
    
    print(f"🔍 Checking for duplicate source references in {project_path}")
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Find all PBXBuildFile entries for RemoteDataStore and DataMigrationService
    pattern = r'(\t\t[A-F0-9]+ /\* (RemoteDataStore|DataMigrationService)\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = [A-F0-9]+ /\* \2\.swift \*/; \};)'
    
    matches = list(re.finditer(pattern, content))
    print(f"   Found {len(matches)} references to RemoteDataStore/DataMigrationService")
    
    if len(matches) <= 2:  # Should have exactly 1 of each
        print("   ✅ No duplicates found")
        return
    
    # Group by filename
    by_file = {}
    for match in matches:
        filename = match.group(2)
        if filename not in by_file:
            by_file[filename] = []
        by_file[filename].append(match)
    
    # Remove duplicates (keep first, remove rest)
    for filename, file_matches in by_file.items():
        if len(file_matches) > 1:
            print(f"   Removing {len(file_matches) - 1} duplicate(s) of {filename}.swift")
            # Remove all but the first
            for match in file_matches[1:]:
                content = content.replace(match.group(1) + '\n', '')
    
    # Also remove from Sources build phase
    # Find the Sources build phase
    sources_phase_pattern = r'(8D0EF79BF179A231B6BF4115 /\* Sources \*/ = \{[^}]+files = \([^)]+)\);'
    sources_match = re.search(sources_phase_pattern, content, re.DOTALL)
    
    if sources_match:
        sources_content = sources_match.group(1)
        original_sources = sources_content
        
        # Find duplicate entries in the sources list
        entry_pattern = r'\t\t\t\t([A-F0-9]+) /\* (RemoteDataStore|DataMigrationService)\.swift in Sources \*/,'
        entries = list(re.finditer(entry_pattern, sources_content))
        
        # Group by filename
        entries_by_file = {}
        for entry in entries:
            filename = entry.group(2)
            if filename not in entries_by_file:
                entries_by_file[filename] = []
            entries_by_file[filename].append(entry)
        
        # Remove duplicates from sources phase
        for filename, file_entries in entries_by_file.items():
            if len(file_entries) > 1:
                print(f"   Removing {len(file_entries) - 1} duplicate source phase entry for {filename}.swift")
                for entry in file_entries[1:]:
                    sources_content = sources_content.replace('\n' + entry.group(0), '')
        
        # Replace in content
        if sources_content != original_sources:
            content = content.replace(original_sources, sources_content)
    
    # Write back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("   ✅ Duplicates removed")

if __name__ == '__main__':
    script_dir = os.path.dirname(__file__)
    project_path = os.path.join(script_dir, '..', 'Nestling', 'Nestling.xcodeproj', 'project.pbxproj')
    project_path = os.path.abspath(project_path)
    
    if not os.path.exists(project_path):
        print(f"❌ Project file not found: {project_path}")
        sys.exit(1)
    
    remove_duplicate_sources(project_path)
    print("✅ Done!")


