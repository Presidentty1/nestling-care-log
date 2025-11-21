#!/usr/bin/env ruby

require 'xcodeproj'

# Get project directory
script_dir = File.dirname(__FILE__)
project_dir = File.expand_path(File.join(script_dir, '..', 'Nestling'))
project_path = File.join(project_dir, 'Nestling.xcodeproj')

puts "📦 Adding Firebase Swift Package dependencies..."
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

# Firebase package URL
firebase_url = 'https://github.com/firebase/firebase-ios-sdk.git'

puts "\n📦 Adding Firebase package..."

# Check if package already exists
existing_package = project.root_object.package_references.find { |p| p.repositoryURL == firebase_url }
if existing_package
  puts "   ⏭️  Firebase package already added"
  package_ref = existing_package
else
  # Create package reference
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = firebase_url
  package_ref.requirement = {
    'kind' => 'upToNextMajorVersion',
    'minimumVersion' => '11.0.0'
  }

  project.root_object.package_references << package_ref
  puts "   ✅ Added Firebase package reference"
end

# Add package products to target
package_ref = project.root_object.package_references.find { |p| p.repositoryURL == firebase_url }
if package_ref
  # Add FirebaseCore product
  existing_core = nestling_target.package_product_dependencies.find { |d| d.package_reference == package_ref && d.product_name == 'FirebaseCore' }

  unless existing_core
    core_product = nestling_target.new_package_product_dependency('FirebaseCore', package_ref)
    puts "   ✅ Added FirebaseCore to Nestling target"
  else
    puts "   ⏭️  FirebaseCore already added to target"
  end

  # Add FirebaseAnalytics product
  existing_analytics = nestling_target.package_product_dependencies.find { |d| d.package_reference == package_ref && d.product_name == 'FirebaseAnalytics' }

  unless existing_analytics
    analytics_product = nestling_target.new_package_product_dependency('FirebaseAnalytics', package_ref)
    puts "   ✅ Added FirebaseAnalytics to Nestling target"
  else
    puts "   ⏭️  FirebaseAnalytics already added to target"
  end
end

# Save project
puts "\n💾 Saving project..."
project.save
puts "✅ Project saved successfully!"

puts "\n🎉 Done! Firebase package dependencies have been added."
puts "\n📝 Next steps:"
puts "   1. Xcode will automatically resolve packages"
puts "   2. Build the project: ⌘B"
puts "   3. Run the app: ⌘R"


