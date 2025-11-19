#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

# Get project directory
script_dir = File.dirname(__FILE__)
project_dir = File.expand_path(File.join(script_dir, '..', 'Nestling'))
project_path = File.join(project_dir, 'Nestling.xcodeproj')

puts "🔍 Opening Xcode project..."
puts "   Project: #{project_path}"

unless File.exist?(project_path)
  puts "❌ ERROR: Project not found at #{project_path}"
  exit 1
end

# Open project
project = Xcodeproj::Project.open(project_path)
puts "✅ Project opened"

# Find targets
nestling_target = project.targets.find { |t| t.name == 'Nestling' }
tests_target = project.targets.find { |t| t.name == 'NestlingTests' }
uitests_target = project.targets.find { |t| t.name == 'NestlingUITests' }

unless nestling_target
  puts "❌ ERROR: Could not find 'Nestling' target"
  exit 1
end

puts "✅ Found targets:"
puts "   - #{nestling_target.name}"
puts "   - #{tests_target.name}" if tests_target
puts "   - #{uitests_target.name}" if uitests_target

# Find main groups
main_group = project.main_group
nestling_group = main_group['Nestling'] || main_group.find_subpath('Nestling', true)
tests_group = main_group['NestlingTests'] || main_group.find_subpath('NestlingTests', true)
uitests_group = main_group['NestlingUITests'] || main_group.find_subpath('NestlingUITests', true)

puts "\n📁 Found groups:"
puts "   - Nestling: #{nestling_group.path}"
puts "   - NestlingTests: #{tests_group.path}" if tests_group
puts "   - NestlingUITests: #{uitests_group.path}" if uitests_group

# Helper function to find or create nested groups
def find_or_create_group(parent_group, path_parts)
  return parent_group if path_parts.empty?
  
  group_name = path_parts.first
  group = parent_group[group_name]
  
  unless group
    group = parent_group.new_group(group_name, group_name)
    puts "   Created group: #{group_name}"
  end
  
  find_or_create_group(group, path_parts[1..-1])
end

# Helper function to add file to project
def add_file_to_project(project, group, file_path, target, target_name)
  # Check if file already exists
  existing_file = group.files.find { |f| f.path == file_path }
  if existing_file
    puts "   ⏭️  Skipping (already added): #{file_path}"
    return existing_file
  end
  
  # Add file reference - use just the filename, not the full path
  # The group structure already represents the folder hierarchy
  file_name = File.basename(file_path)
  file_ref = group.new_reference(file_path)
  
  # Set the path correctly - relative to the group's path
  file_ref.path = file_path
  
  # Add to target's sources build phase
  if target
    target.source_build_phase.add_file_reference(file_ref)
    puts "   ✅ Added to #{target_name}: #{file_path}"
  end
  
  file_ref
end

# Find all Swift files
def find_swift_files(directory)
  files = []
  return files unless Dir.exist?(directory)
  
  Dir.glob(File.join(directory, '**', '*.swift')).each do |file|
    rel_path = Pathname.new(file).relative_path_from(Pathname.new(directory)).to_s
    files << { path: rel_path, full_path: file }
  end
  
  files.sort_by { |f| f[:path] }
end

puts "\n📝 Scanning for Swift files..."

# Add Nestling source files
nestling_source_dir = File.join(project_dir, 'Nestling')
if Dir.exist?(nestling_source_dir)
  nestling_files = find_swift_files(nestling_source_dir)
  puts "   Found #{nestling_files.length} files in Nestling/"
  
    nestling_files.each do |file_info|
      file_path = file_info[:path]
      parts = file_path.split(File::SEPARATOR)
      
      # Create nested groups if needed
      if parts.length > 1
        group_path = parts[0..-2]
        target_group = find_or_create_group(nestling_group, group_path)
        # For nested files, use relative path from the group
        relative_path = parts[-1]
      else
        target_group = nestling_group
        relative_path = file_path
      end
      
      # Add file with correct path
      file_ref = target_group.new_reference(relative_path)
      file_ref.path = relative_path
      
      # Add to target's sources build phase
      nestling_target.source_build_phase.add_file_reference(file_ref)
      puts "   ✅ Added to Nestling: #{file_path}"
    end
else
  puts "   ⚠️  Nestling/ directory not found"
end

# Add test files
if tests_target && tests_group
  tests_source_dir = File.join(project_dir, 'NestlingTests')
  if Dir.exist?(tests_source_dir)
    test_files = find_swift_files(tests_source_dir)
    puts "\n   Found #{test_files.length} files in NestlingTests/"
    
    test_files.each do |file_info|
      file_path = file_info[:path]
      add_file_to_project(project, tests_group, file_path, tests_target, 'NestlingTests')
    end
  end
end

# Add UI test files
if uitests_target && uitests_group
  uitests_source_dir = File.join(project_dir, 'NestlingUITests')
  if Dir.exist?(uitests_source_dir)
    uitest_files = find_swift_files(uitests_source_dir)
    puts "\n   Found #{uitest_files.length} files in NestlingUITests/"
    
    uitest_files.each do |file_info|
      file_path = file_info[:path]
      add_file_to_project(project, uitests_group, file_path, uitests_target, 'NestlingUITests')
    end
  end
end

# Add Assets.xcassets if it exists
assets_path = File.join(project_dir, 'Nestling.xcodeproj', 'Assets.xcassets')
if Dir.exist?(assets_path)
  puts "\n📦 Adding Assets.xcassets..."
  assets_ref = nestling_group.new_reference('Assets.xcassets')
  assets_ref.last_known_file_type = 'folder.assetcatalog'
  nestling_target.resources_build_phase.add_file_reference(assets_ref)
  puts "   ✅ Added Assets.xcassets"
end

# Save project
puts "\n💾 Saving project..."
project.save
puts "✅ Project saved successfully!"

puts "\n🎉 Done! All files have been added to the Xcode project."
puts "\n📝 Next steps:"
puts "   1. Open the project in Xcode: open #{project_path}"
puts "   2. Build the project: ⌘B"
puts "   3. Run the app: ⌘R"

