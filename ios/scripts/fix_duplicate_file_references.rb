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

puts "📋 Checking for duplicate file references pointing to same physical file..."

# Track file references by their actual file path
file_refs_by_path = {}
duplicate_refs = []

# First pass: identify all file references and group by actual file path
project.files.each do |file_ref|
  next unless file_ref.path && file_ref.path.end_with?('.swift')
  
  begin
    # Try to get the real path
    real_path = file_ref.real_path.to_s
    next unless real_path && File.exist?(real_path)
    
    normalized_path = File.expand_path(real_path)
    
    if file_refs_by_path[normalized_path]
      # This is a duplicate file reference
      duplicate_refs << file_ref
      puts "  ⚠️  Found duplicate file reference: #{File.basename(real_path)} (#{file_ref.uuid})"
    else
      file_refs_by_path[normalized_path] = file_ref
    end
  rescue => e
    # Skip if we can't resolve the path
    next
  end
end

puts "\n📋 Consolidating duplicate file references..."

# For each set of duplicates, keep the first one and remove others from build phase
duplicate_refs.each do |duplicate_ref|
  begin
    real_path = duplicate_ref.real_path.to_s
    next unless real_path && File.exist?(real_path)
    
    normalized_path = File.expand_path(real_path)
    primary_ref = file_refs_by_path[normalized_path]
    
    # Remove duplicate from build phase if it's there
    sources_build_phase.files.each do |build_file|
      if build_file.file_ref == duplicate_ref
        puts "  🗑️  Removing duplicate from build phase: #{File.basename(real_path)}"
        sources_build_phase.remove_file_reference(duplicate_ref)
        break
      end
    end
    
    # Remove the duplicate file reference from the project
    project.files.delete(duplicate_ref)
    puts "  🗑️  Removed duplicate file reference: #{File.basename(real_path)} (#{duplicate_ref.uuid})"
  rescue => e
    puts "  ⚠️  Error processing duplicate: #{e.message}"
    next
  end
end

if duplicate_refs.length > 0
  project.save
  puts "\n✅ Removed #{duplicate_refs.length} duplicate file references"
  puts "💾 Project saved"
else
  puts "\n✅ No duplicate file references found"
end

puts "\n🎉 Done! Try building in Xcode now."

