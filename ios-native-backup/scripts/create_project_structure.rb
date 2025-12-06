#!/usr/bin/env ruby

# Xcode Project Structure Generator
# This script creates a basic .xcodeproj structure that can be opened in Xcode
# Note: This is a simplified version. Full project setup still requires Xcode GUI.

require 'fileutils'
require 'xcodeproj'

# Check if xcodeproj gem is available
begin
  require 'xcodeproj'
rescue LoadError
  puts "⚠️  xcodeproj gem not found. Installing..."
  system("gem install xcodeproj")
  require 'xcodeproj'
end

puts "🚀 Creating Xcode Project Structure"
puts "===================================="
puts ""

# Get current directory
project_dir = File.expand_path(File.dirname(__FILE__) + "/..")
project_name = "Nestling"
project_path = File.join(project_dir, "#{project_name}.xcodeproj")

# Check if project already exists
if File.exist?(project_path)
  puts "⚠️  Project already exists at #{project_path}"
  print "Overwrite? (y/n): "
  exit unless gets.chomp.downcase == 'y'
end

puts "Creating project: #{project_path}"

# Create new Xcode project
project = Xcodeproj::Project.new(project_path)

# Create main app target
app_target = project.new_target(:application, project_name, :ios, '17.0')

# Configure target
app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.nestling.app'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone and iPad
end

# Add source files
sources_dir = File.join(project_dir, "Sources")
if File.exist?(sources_dir)
  puts "Adding source files..."
  
  # Add App group
  app_group = project.main_group.new_group('Sources')
  
  # Recursively add Swift files
  def add_files_to_group(project, group, dir_path, target)
    Dir.glob(File.join(dir_path, '*')).each do |item|
      if File.directory?(item)
        sub_group = group.new_group(File.basename(item))
        add_files_to_group(project, sub_group, item, target)
      elsif item.end_with?('.swift')
        file_ref = group.new_file(item)
        target.add_file_references([file_ref])
      end
    end
  end
  
  add_files_to_group(project, app_group, sources_dir, app_target)
end

# Add Info.plist
info_plist_path = File.join(project_dir, "Nestling", "Info.plist")
if File.exist?(info_plist_path)
  info_plist_ref = project.main_group.new_file(info_plist_path)
  app_target.build_configurations.each do |config|
    config.build_settings['INFOPLIST_FILE'] = 'Nestling/Info.plist'
  end
end

# Add Assets
assets_path = File.join(project_dir, "Nestling", "Assets.xcassets")
if File.exist?(assets_path)
  assets_ref = project.main_group.new_group('Assets').new_file(assets_path)
  app_target.add_resources([assets_ref])
end

# Add Entitlements
entitlements_path = File.join(project_dir, "Nestling", "Entitlements.entitlements")
if File.exist?(entitlements_path)
  entitlements_ref = project.main_group.new_file(entitlements_path)
  app_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Nestling/Entitlements.entitlements'
  end
end

# Save project
project.save

puts ""
puts "✅ Project created at #{project_path}"
puts ""
puts "⚠️  Note: This is a basic structure. You still need to:"
puts "   1. Open project in Xcode"
puts "   2. Verify all files are added to targets"
puts "   3. Add Core Data model to target"
puts "   4. Configure code signing"
puts ""
puts "📚 See QUICK_START.md for next steps"


