#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

# Get project directory
script_dir = File.dirname(__FILE__)
project_dir = File.expand_path(File.join(script_dir, '..', 'Nestling'))
project_path = File.join(project_dir, 'Nestling.xcodeproj')

puts "🔧 Fixing file paths in Xcode project..."
puts "   Project: #{project_path}"

# Open project
project = Xcodeproj::Project.open(project_path)
puts "✅ Project opened"

# Find targets
nestling_target = project.targets.find { |t| t.name == 'Nestling' }
tests_target = project.targets.find { |t| t.name == 'NestlingTests' }
uitests_target = project.targets.find { |t| t.name == 'NestlingUITests' }

# Find main groups
main_group = project.main_group
nestling_group = main_group['Nestling'] || main_group.find_subpath('Nestling', true)
tests_group = main_group['NestlingTests'] || main_group.find_subpath('NestlingTests', true)
uitests_group = main_group['NestlingUITests'] || main_group.find_subpath('NestlingUITests', true)

puts "\n🗑️  Removing all incorrectly added files..."

# Remove all files from build phases
[nestling_target, tests_target, uitests_target].compact.each do |target|
  target.source_build_phase.files.each do |build_file|
    build_file.remove_from_project
  end
end

# Remove all file references
def remove_all_files(group)
  group.files.each { |f| f.remove_from_project }
  group.children.each { |child| remove_all_files(child) if child.is_a?(Xcodeproj::Project::Object::PBXGroup) }
end

remove_all_files(nestling_group)
remove_all_files(tests_group) if tests_group
remove_all_files(uitests_group) if uitests_group

puts "✅ Removed all files"

# Helper to find or create group
def find_or_create_group(parent_group, path_parts)
  return parent_group if path_parts.empty?
  
  group_name = path_parts.first
  group = parent_group[group_name]
  
  unless group
    group = parent_group.new_group(group_name, group_name)
  end
  
  find_or_create_group(group, path_parts[1..-1])
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

puts "\n📝 Re-adding files with correct paths..."

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
      # Use just the filename for the file reference
      file_name = parts[-1]
    else
      target_group = nestling_group
      file_name = file_path
    end
    
    # Add file reference with just the filename
    file_ref = target_group.new_reference(file_name)
    file_ref.path = file_name
    
    # Add to target's sources build phase
    nestling_target.source_build_phase.add_file_reference(file_ref)
  end
  puts "   ✅ Added #{nestling_files.length} files to Nestling target"
end

# Add test files
if tests_target && tests_group
  tests_source_dir = File.join(project_dir, 'NestlingTests')
  if Dir.exist?(tests_source_dir)
    test_files = find_swift_files(tests_source_dir)
    puts "   Found #{test_files.length} files in NestlingTests/"
    
    test_files.each do |file_info|
      file_name = File.basename(file_info[:path])
      file_ref = tests_group.new_reference(file_name)
      file_ref.path = file_name
      tests_target.source_build_phase.add_file_reference(file_ref)
    end
    puts "   ✅ Added #{test_files.length} files to NestlingTests target"
  end
end

# Add UI test files
if uitests_target && uitests_group
  uitests_source_dir = File.join(project_dir, 'NestlingUITests')
  if Dir.exist?(uitests_source_dir)
    uitest_files = find_swift_files(uitests_source_dir)
    puts "   Found #{uitest_files.length} files in NestlingUITests/"
    
    uitest_files.each do |file_info|
      file_name = File.basename(file_info[:path])
      file_ref = uitests_group.new_reference(file_name)
      file_ref.path = file_name
      uitests_target.source_build_phase.add_file_reference(file_ref)
    end
    puts "   ✅ Added #{uitest_files.length} files to NestlingUITests target"
  end
end

# Save project
puts "\n💾 Saving project..."
project.save
puts "✅ Project saved successfully!"

puts "\n🎉 Done! File paths have been fixed."
puts "\n📝 Next steps:"
puts "   1. Build the project: ⌘B"
puts "   2. Run the app: ⌘R"

