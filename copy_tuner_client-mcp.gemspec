# frozen_string_literal: true

require_relative "lib/copy_tuner_client/mcp/version"

Gem::Specification.new do |spec|
  spec.name = "copy_tuner_client-mcp"
  spec.version = CopyTunerClient::Mcp::VERSION
  spec.authors = ["SonicGarden"]
  spec.email = ["info@sonicgarden.jp"]

  spec.summary = "MCP server for CopyTuner Rails i18n translation management service"
  spec.description = "Rails i18n translation management service 'CopyTuner' MCP (Model Context Protocol) server implementation."
  spec.homepage = "https://github.com/SonicGarden/copy_tuner_client-mcp"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/SonicGarden/copy_tuner_client-mcp"
  spec.metadata["changelog_uri"] = "https://github.com/SonicGarden/copy_tuner_client-mcp/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new depende
  spec.add_dependency "copy_tuner_client", ">= 1.0.0"
  spec.add_dependency "mcp", "~> 0.1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
