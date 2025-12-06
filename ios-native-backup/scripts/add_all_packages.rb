#!/usr/bin/env ruby

require 'xcodeproj'

# Get project directory
script_dir = File.dirname(__FILE__)
project_dir = File.expand_path(File.join(script_dir, '..', 'Nestling'))
project_path = File.join(project_dir, 'Nestling.xcodeproj')

puts "📦 Adding all Swift Package dependencies..."
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

# Package definitions
packages = [
  {
    name: 'Firebase',
    url: 'https://github.com/firebase/firebase-ios-sdk.git',
    version: '11.0.0',
    products: ['FirebaseCore', 'FirebaseAnalytics']
  },
  {
    name: 'Supabase',
    url: 'https://github.com/supabase/supabase-swift.git',
    version: '2.0.0',
    products: ['Supabase']
  },
  {
    name: 'Sentry',
    url: 'https://github.com/getsentry/sentry-cocoa.git',
    version: '8.0.0',
    products: ['Sentry']
  }
]

packages.each do |pkg|
  puts "\n📦 Adding #{pkg[:name]} package..."
  
  # Check if package already exists
  existing_package = project.root_object.package_references.find { |p| p.repositoryURL == pkg[:url] }
  if existing_package
    puts "   ⏭️  #{pkg[:name]} package already added"
    package_ref = existing_package
  else
    # Create package reference
    package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    package_ref.repositoryURL = pkg[:url]
    package_ref.requirement = {
      'kind' => 'upToNextMajorVersion',
      'minimumVersion' => pkg[:version]
    }
    
    project.root_object.package_references << package_ref
    puts "   ✅ Added #{pkg[:name]} package reference"
  end
  
  # Add package products to target
  package_ref = project.root_object.package_references.find { |p| p.repositoryURL == pkg[:url] }
  if package_ref
    pkg[:products].each do |product_name|
      existing_product = nestling_target.package_product_dependencies.find { |d| d.package_reference == package_ref && d.product_name == product_name }
      
      unless existing_product
        nestling_target.new_package_product_dependency(product_name, package_ref)
        puts "   ✅ Added #{product_name} to Nestling target"
      else
        puts "   ⏭️  #{product_name} already added to target"
      end
    end
  end
end

# Save project
puts "\n💾 Saving project..."
project.save
puts "✅ Project saved successfully!"

puts "\n🎉 Done! All package dependencies have been added."
puts "\n📝 Next steps:"
puts "   1. Open Xcode and let it resolve packages automatically"
puts "   2. Build the project: ⌘B"
puts "   3. Run the app: ⌘R"


