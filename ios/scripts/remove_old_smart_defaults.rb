#!/usr/bin/env ruby
require 'xcodeproj'

project_path = File.expand_path('../Nuzzle/Nestling.xcodeproj', __FILE__)
project = Xcodeproj::Project.open(project_path)

# Find the file reference for the deleted file
file_refs_to_remove = project.files.select { |f| f.path == 'SmartDefaultsService.swift' && f.parent.path == 'Onboarding' }

if file_refs_to_remove.empty?
  # Fallback: look by full path or group structure
  file_refs_to_remove = project.files.select { |f| f.path == 'SmartDefaultsService.swift' && f.hierarchy_path.include?('Onboarding') }
end

if file_refs_to_remove.empty?
    puts "No file reference found for Onboarding/SmartDefaultsService.swift"
else 
    puts "Found #{file_refs_to_remove.count} references to remove."
    file_refs_to_remove.each do |ref|
        ref.remove_from_project
        puts "Removed reference: #{ref}"
    end
    project.save
    puts "Project saved."
end

