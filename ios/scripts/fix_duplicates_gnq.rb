#!/usr/bin/env ruby

require 'xcodeproj'

project_path = File.expand_path(File.join(__dir__, '..', 'Nuzzle', 'Nestling.xcodeproj'))

puts "🔍 Opening Xcode project at #{project_path}..."
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Nuzzle' }
unless target
  puts "❌ ERROR: Could not find 'Nuzzle' target"
  exit 1
end

sources_build_phase = target.source_build_phase
unless sources_build_phase
  puts "❌ ERROR: Could not find Sources build phase"
  exit 1
end

puts "📋 Checking for duplicate files in Compile Sources build phase..."

# Track files by their file reference UUID to find duplicates
file_refs_seen = {}
duplicates_removed = 0
files_to_remove = []

# First pass: identify duplicates by file reference UUID
sources_build_phase.files.each do |build_file|
  next unless build_file.file_ref
  
  file_ref_uuid = build_file.file_ref.uuid
  
  if file_refs_seen[file_ref_uuid]
    # This is a duplicate - mark for removal
    files_to_remove << build_file
    duplicates_removed += 1
    file_name = build_file.file_ref.path || build_file.file_ref.name || 'Unknown'
    puts "  ⚠️  Found duplicate: #{file_name}"
  else
    file_refs_seen[file_ref_uuid] = true
  end
end

# Remove duplicates
files_to_remove.each do |duplicate|
  sources_build_phase.remove_file_reference(duplicate.file_ref)
end

if duplicates_removed > 0
  project.save
  puts "✅ Removed #{duplicates_removed} duplicate file references"
  puts "💾 Project saved"
else
  puts "✅ No duplicates found"
end

puts "\n🎉 Done! Try building in Xcode now."

