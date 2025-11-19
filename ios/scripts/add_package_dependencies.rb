#!/usr/bin/env ruby

require 'xcodeproj'

# Get project directory
script_dir = File.dirname(__FILE__)
project_dir = File.expand_path(File.join(script_dir, '..', 'Nestling'))
project_path = File.join(project_dir, 'Nestling.xcodeproj')

puts "📦 Adding Swift Package dependencies..."
puts "   Project: #{project_path}"

# Open project
project = Xcodeproj::Project.open(project_path)
puts "✅ Project opened"

# Find Nestling target
nestling_target = project.targets.find { |t| t.name == 'Nestling' }
unless nestling_target
  puts "❌ ERROR: Could not find 'Nestling' target"
  exit 1
end

puts "✅ Found target: #{nestling_target.name}"

# Add Swift Package Manager repository
# ZipArchive package URL
ziparchive_url = 'https://github.com/ZipArchive/ZipArchive.git'

puts "\n📦 Adding ZipArchive package..."

# Check if package already exists
existing_package = project.root_object.package_references.find { |p| p.repositoryURL == ziparchive_url }
if existing_package
  puts "   ⏭️  ZipArchive package already added"
  package_ref = existing_package
else
  # Create package reference
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = ziparchive_url
  package_ref.requirement = {
    'kind' => 'upToNextMajorVersion',
    'minimumVersion' => '2.5.0'
  }
  
  project.root_object.package_references << package_ref
  puts "   ✅ Added ZipArchive package reference"
end

# Add package product to target
package_ref = project.root_object.package_references.find { |p| p.repositoryURL == ziparchive_url }
if package_ref
  # Check if already added to target
  existing_dependency = nestling_target.package_product_dependencies.find { |d| d.package_reference == package_ref && d.product_name == 'ZipArchive' }
  
  unless existing_dependency
    package_product = nestling_target.new_package_product_dependency('ZipArchive', package_ref)
    puts "   ✅ Added ZipArchive to Nestling target"
  else
    puts "   ⏭️  ZipArchive already added to target"
  end
end

# Save project
puts "\n💾 Saving project..."
project.save
puts "✅ Project saved successfully!"

puts "\n🎉 Done! Package dependencies have been added."
puts "\n📝 Next steps:"
puts "   1. Xcode will automatically resolve packages"
puts "   2. Build the project: ⌘B"
puts "   3. Run the app: ⌘R"

