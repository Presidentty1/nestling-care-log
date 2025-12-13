#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ios/Nuzzle/Nestling.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'Nuzzle' }
raise "Could not find Nuzzle target" unless target

# Add LegalDocumentView.swift to the Settings group
settings_group = project.main_group.find_subpath('Nestling/Features/Settings', true)
raise "Could not find Settings group" unless settings_group

legal_view_file = settings_group.new_file('LegalDocumentView.swift')
target.add_file_references([legal_view_file])

# Add HTML files to Resources
resources_group = project.main_group.find_subpath('Nestling/Resources', true)
raise "Could not find Resources group" unless resources_group

legal_group = resources_group.new_group('Legal')
privacy_file = legal_group.new_file('privacy_policy.html')
terms_file = legal_group.new_file('terms_of_use.html')

# Set the correct paths
privacy_file.path = 'Resources/Legal/privacy_policy.html'
terms_file.path = 'Resources/Legal/terms_of_use.html'

# Add HTML files to the Resources build phase
resources_build_phase = target.build_phases.find { |bp| bp.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase) }
raise "Could not find Resources build phase" unless resources_build_phase

resources_build_phase.add_file_reference(privacy_file)
resources_build_phase.add_file_reference(terms_file)

# Save the project
project.save

puts "Successfully added files to Xcode project!"

