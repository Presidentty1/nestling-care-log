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
# Sentry package URL
sentry_url = 'https://github.com/getsentry/sentry-cocoa.git'

puts "\n📦 Adding Sentry package..."

# Check if package already exists
existing_package = project.root_object.package_references.find { |p| p.repositoryURL == sentry_url }
if existing_package
  puts "   ⏭️  Sentry package already added"
  package_ref = existing_package
else
  # Create package reference
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = sentry_url
  package_ref.requirement = {
    'kind' => 'upToNextMajorVersion',
    'minimumVersion' => '8.0.0'
  }

  project.root_object.package_references << package_ref
  puts "   ✅ Added Sentry package reference"
end

# Add package products to target
package_ref = project.root_object.package_references.find { |p| p.repositoryURL == sentry_url }
if package_ref
  # Add Sentry product
  existing_sentry = nestling_target.package_product_dependencies.find { |d| d.package_reference == package_ref && d.product_name == 'Sentry' }

  unless existing_sentry
    sentry_product = nestling_target.new_package_product_dependency('Sentry', package_ref)
    puts "   ✅ Added Sentry to Nestling target"
  else
    puts "   ⏭️  Sentry already added to target"
  end

  # Add SentrySwiftUI product (for SwiftUI integration)
  existing_swiftui = nestling_target.package_product_dependencies.find { |d| d.package_reference == package_ref && d.product_name == 'SentrySwiftUI' }

  unless existing_swiftui
    swiftui_product = nestling_target.new_package_product_dependency('SentrySwiftUI', package_ref)
    puts "   ✅ Added SentrySwiftUI to Nestling target"
  else
    puts "   ⏭️  SentrySwiftUI already added to target"
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

