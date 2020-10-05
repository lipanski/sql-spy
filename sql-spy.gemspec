Gem::Specification.new do |spec|
  spec.name = "sql_spy"
  spec.version = "0.1.0"
  spec.authors = ["Florin Lipan"]
  spec.email = ["florinlipan@gmail.com"]

  spec.summary = %q{A gem to track SQL queries triggered by a particular block of code}
  spec.homepage = "https://github.com/lipanski/sql-spy"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/lipanski/sql-spy"
  spec.metadata["changelog_uri"] = "https://github.com/lipanski/sql-spy/releases"

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
end
