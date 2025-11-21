#!/usr/bin/env python3
"""
Add Swift Package dependencies to Xcode project programmatically.
"""

import re
import sys
import os

# Package definitions
PACKAGES = [
    {
        'name': 'Firebase',
        'url': 'https://github.com/firebase/firebase-ios-sdk.git',
        'version': '11.0.0',
        'products': ['FirebaseCore', 'FirebaseAnalytics']
    },
    {
        'name': 'Supabase',
        'url': 'https://github.com/supabase/supabase-swift.git',
        'version': '2.0.0',
        'products': ['Supabase']
    },
    {
        'name': 'Sentry',
        'url': 'https://github.com/getsentry/sentry-cocoa.git',
        'version': '8.0.0',
        'products': ['Sentry']
    }
]

def add_packages_to_project(project_path):
    """Add Swift Package dependencies to Xcode project."""
    
    print(f"📦 Adding Swift Package dependencies to {project_path}")
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Check if packages section exists
    if 'XCRemoteSwiftPackageReference' in content:
        print("   ⚠️  Package references already exist. Checking if all packages are present...")
        # Check each package
        for pkg in PACKAGES:
            if pkg['url'] not in content:
                print(f"   ❌ Missing: {pkg['name']}")
            else:
                print(f"   ✅ Found: {pkg['name']}")
        return
    
    # Find the root object section
    root_object_match = re.search(r'rootObject = ([A-F0-9]+) /\* Project object \*/;', content)
    if not root_object_match:
        print("   ❌ Could not find root object")
        return
    
    root_object_id = root_object_match.group(1)
    
    # Find the project object
    project_match = re.search(
        rf'{re.escape(root_object_id)} /\* Project object \*/ = \{{[^}}]*isa = PBXProject;[^}}]*\}}',
        content,
        re.DOTALL
    )
    
    if not project_match:
        print("   ❌ Could not find project object")
        return
    
    # Generate unique IDs for package references
    import uuid
    package_refs = []
    package_deps = []
    
    for pkg in PACKAGES:
        # Generate IDs
        ref_id = ''.join([format(ord(c), '02X') for c in uuid.uuid4().hex[:12].upper()])
        for product in pkg['products']:
            dep_id = ''.join([format(ord(c), '02X') for c in uuid.uuid4().hex[:12].upper()])
            package_deps.append({
                'id': dep_id,
                'ref_id': ref_id,
                'product': product
            })
        
        package_refs.append({
            'id': ref_id,
            'url': pkg['url'],
            'version': pkg['version']
        })
    
    # Find where to insert package references (before rootObject)
    # We'll add them to the objects section
    
    # Add package references section
    package_refs_section = "\n/* Begin XCRemoteSwiftPackageReference section */\n"
    for ref in package_refs:
        package_refs_section += f"""		{ref['id']} /* {ref['url'].split('/')[-1].replace('.git', '')} */ = {{
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "{ref['url']}";
			requirement = {{
				kind = upToNextMajorVersion;
				minimumVersion = {ref['version']};
			}};
		}};
"""
    package_refs_section += "/* End XCRemoteSwiftPackageReference section */\n"
    
    # Find the Nestling target
    target_match = re.search(
        r'(7F391E6AA62B3B0316F1C27B /\* Nestling \*/ = \{[^}}]*isa = PBXNativeTarget;[^}}]*packageProductDependencies = )\(([^)]*)\)',
        content,
        re.DOTALL
    )
    
    if target_match:
        # Add package dependencies to existing array
        existing_deps = target_match.group(2).strip()
        deps_section = existing_deps + "\n" if existing_deps else ""
        for dep in package_deps:
            deps_section += f"""				{dep['id']} /* {dep['product']} */,
"""
        
        # Replace the packageProductDependencies section
        new_target_section = target_match.group(1) + "(\n" + deps_section + "\t\t\t);"
        content = content[:target_match.start()] + new_target_section + content[target_match.end():]
    else:
        # Need to add packageProductDependencies to target
        target_full_match = re.search(
            r'(7F391E6AA62B3B0316F1C27B /\* Nestling \*/ = \{[^}}]*isa = PBXNativeTarget;[^}}]*)(buildPhases = \([^)]*\);)',
            content,
            re.DOTALL
        )
        if target_full_match:
            deps_section = "\t\t\tpackageProductDependencies = (\n"
            for dep in package_deps:
                deps_section += f"""				{dep['id']} /* {dep['product']} */,
"""
            deps_section += "\t\t\t);\n"
            content = content[:target_full_match.end(1)] + deps_section + target_full_match.group(2) + content[target_full_match.end():]
    
    # Add package product dependencies section
    package_deps_section = "\n/* Begin XCSwiftPackageProductDependency section */\n"
    for dep in package_deps:
        package_deps_section += f"""		{dep['id']} /* {dep['product']} */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {dep['ref_id']} /* {dep['ref_id']} */;
			productName = {dep['product']};
		}};
"""
    package_deps_section += "/* End XCSwiftPackageProductDependency section */\n"
    
    # Add package references to root object
    root_obj_match = re.search(
        rf'({re.escape(root_object_id)} /\* Project object \*/ = \{{[^}}]*isa = PBXProject;[^}}]*)',
        content,
        re.DOTALL
    )
    
    if root_obj_match:
        # Check if packageReferences exists
        if 'packageReferences = (' not in root_obj_match.group(1):
            # Add packageReferences array
            package_refs_list = "\t\tpackageReferences = (\n"
            for ref in package_refs:
                package_refs_list += f"""			{ref['id']} /* {ref['url'].split('/')[-1].replace('.git', '')} */,
"""
            package_refs_list += "\t\t);\n"
            # Insert before the closing brace
            insert_pos = root_obj_match.end(1) - 1
            content = content[:insert_pos] + package_refs_list + "\t" + content[insert_pos:]
    
    # Insert package reference and dependency sections before the closing brace of objects section
    objects_end = content.rfind('/* End PBXFileReference section */')
    if objects_end > 0:
        # Find a good insertion point
        insert_point = content.find('\n\t};', objects_end)
        if insert_point > 0:
            content = content[:insert_point] + package_refs_section + package_deps_section + content[insert_point:]
    
    # Write back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("   ✅ Package references added to project file")
    print("\n📝 Next steps:")
    print("   1. Open Xcode and let it resolve packages")
    print("   2. Build the project: ⌘B")

if __name__ == '__main__':
    script_dir = os.path.dirname(__file__)
    project_path = os.path.join(script_dir, '..', 'Nestling', 'Nestling.xcodeproj', 'project.pbxproj')
    project_path = os.path.abspath(project_path)
    
    if not os.path.exists(project_path):
        print(f"❌ Project file not found: {project_path}")
        sys.exit(1)
    
    add_packages_to_project(project_path)


