#!/usr/bin/env ruby
# tool/l10n/add_lproj.rb — adds ios/Runner/<lang>.lproj/InfoPlist.strings to the
# Runner target as one variant group. Idempotent. Uses the xcodeproj gem that
# ships with CocoaPods.
require 'xcodeproj'
proj = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = proj.targets.find { |t| t.name == 'Runner' }
group = proj.main_group['Runner']
variant = group.children.find { |c| c.isa == 'PBXVariantGroup' && c.name == 'InfoPlist.strings' } ||
          group.new_variant_group('InfoPlist.strings')
Dir.glob('ios/Runner/*.lproj/InfoPlist.strings').sort.each do |path|
  lang = File.basename(File.dirname(path), '.lproj')
  next if variant.children.any? { |c| c.name == lang }
  ref = variant.new_reference(path.sub('ios/Runner/', ''))
  ref.name = lang
  proj.root_object.known_regions |= [lang]
end
unless runner.resources_build_phase.files_references.include?(variant)
  runner.resources_build_phase.add_file_reference(variant)
end
proj.save
puts "regions: #{proj.root_object.known_regions.join(', ')}"
