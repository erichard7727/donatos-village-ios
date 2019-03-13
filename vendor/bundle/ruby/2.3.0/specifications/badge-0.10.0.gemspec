# -*- encoding: utf-8 -*-
# stub: badge 0.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "badge".freeze
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Griesser".freeze]
  s.date = "2018-11-27"
  s.description = "0.10.0".freeze
  s.email = ["daniel.griesser.86@gmail.com".freeze]
  s.executables = ["badge".freeze]
  s.files = ["bin/badge".freeze]
  s.homepage = "https://github.com/HazAT/badge".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Add a badge overlay to your app icon".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<curb>.freeze, ["~> 0.9"])
      s.add_runtime_dependency(%q<fastlane>.freeze, [">= 2.0"])
      s.add_runtime_dependency(%q<fastimage>.freeze, [">= 1.6"])
      s.add_runtime_dependency(%q<mini_magick>.freeze, [">= 4.5"])
    else
      s.add_dependency(%q<curb>.freeze, ["~> 0.9"])
      s.add_dependency(%q<fastlane>.freeze, [">= 2.0"])
      s.add_dependency(%q<fastimage>.freeze, [">= 1.6"])
      s.add_dependency(%q<mini_magick>.freeze, [">= 4.5"])
    end
  else
    s.add_dependency(%q<curb>.freeze, ["~> 0.9"])
    s.add_dependency(%q<fastlane>.freeze, [">= 2.0"])
    s.add_dependency(%q<fastimage>.freeze, [">= 1.6"])
    s.add_dependency(%q<mini_magick>.freeze, [">= 4.5"])
  end
end
