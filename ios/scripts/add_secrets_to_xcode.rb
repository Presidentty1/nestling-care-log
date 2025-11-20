#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

script_dir = File.dirname(__FILE__)
project_dir = File.expand_path(File.join(script_dir, '..', 'Nestling'))
project_path = File.join(project_dir, 'Nestling.xcodeproj')

puts "🔍 Opening Xcode project..."
unless File.exist?(project_path)
  puts "❌ ERROR: Project not found at #{project_path}"
  exit 1
end

project = Xcodeproj::Project.open(project_path)

nestling_target = project.targets.find { |t| t.name == 'Nestling' }
unless nestling_target
  puts "❌ ERROR: Could not find 'Nestling' target"
  exit 1
end

services_group = project.main_group.find_subpath('Nestling/Services', true)
unless services_group
  puts "❌ ERROR: Could not find or create 'Nestling/Services' group"
  exit 1
end

file_name = "Secrets.swift"
file_path = "Services/#{file_name}" # Path relative to Nestling group
full_file_path = File.join(project_dir, 'Nestling', file_path)

# Check if file reference already exists
existing_ref = services_group.files.find { |f| f.path == file_name }
if existing_ref
  puts "⚠️  File #{file_name} already exists in project"
  # Check if it's in the build phase
  unless nestling_target.source_build_phase.files_references.include?(existing_ref)
    nestling_target.source_build_phase.add_file_reference(existing_ref)
    puts "   ✅ Added to target's sources build phase"
  else
    puts "   ✅ Already in target's sources build phase"
  end
else
  # Add file reference
  file_ref = services_group.new_reference(file_path)
  file_ref.path = file_path # Ensure path is correct
  
  # Add to target's sources build phase
  nestling_target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added file: #{file_path}"
end

project.save
puts "💾 Project saved"

