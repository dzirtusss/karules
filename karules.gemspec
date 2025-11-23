# frozen_string_literal: true

require_relative "lib/karules/version"

Gem::Specification.new do |spec|
  spec.name = "karules"
  spec.version = Karules::VERSION
  spec.authors = ["Sergey Tarasov"]
  spec.email = ["dzirtusss@gmail.com"]

  spec.summary = "Configure Karabiner-Elements with Ruby DSL"
  spec.description = "A Ruby DSL for configuring Karabiner-Elements - cleaner, more maintainable keyboard customization for macOS"
  spec.homepage = "https://github.com/dzirtusss/karules"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{exe,lib,examples}/**/*") + %w[LICENSE README.md CHANGELOG.md]
  spec.bindir = "exe"
  spec.executables = ["karules"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency("rubocop", "~> 1.69")
  spec.metadata["rubygems_mfa_required"] = "true"
end
