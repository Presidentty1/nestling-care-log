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

puts "📋 Checking for duplicate files by actual file path..."

# Track files by their actual file path
file_paths = {}
duplicates_removed = 0
files_to_remove = []

# First pass: identify duplicates by actual file path
sources_build_phase.files.each do |build_file|
  next unless build_file.file_ref
  
  begin
    file_path = build_file.file_ref.real_path.to_s
    next unless file_path && File.exist?(file_path)
    
    normalized_path = File.expand_path(file_path)
    
    if file_paths[normalized_path]
      # This is a duplicate - mark for removal
      files_to_remove << build_file
      duplicates_removed += 1
      file_name = File.basename(file_path)
      puts "  ⚠️  Found duplicate: #{file_name}"
    else
      file_paths[normalized_path] = build_file
    end
  rescue => e
    # Skip if we can't resolve the path
    next
  end
end

# Remove duplicates (keep the first occurrence)
files_to_remove.each do |duplicate|
  sources_build_phase.remove_file_reference(duplicate.file_ref)
end

if duplicates_removed > 0
  project.save
  puts "✅ Removed #{duplicates_removed} duplicate file references"
  puts "💾 Project saved"
else
  puts "✅ No duplicates found by file path"
end

puts "\n🎉 Done! Try building in Xcode now."

