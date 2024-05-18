require_relative "lib/swombat_tools/version"

Gem::Specification.new do |spec|
  spec.name        = "swombat_tools"
  spec.version     = SwombatTools::VERSION
  spec.authors     = ["swombat"]
  spec.email       = ["daniel.github@tenner.org"]
  spec.homepage    = "https://danieltenner.com"
  spec.summary     = "My tools for BT projects"
  spec.description = "n/a"
  spec.license     = "none"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "no push"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/swombat/swombat_tools"
  spec.metadata["changelog_uri"] = "https://github.com/swombat/swombat_tools"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.3.3"
end
