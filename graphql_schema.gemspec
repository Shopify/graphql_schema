require_relative 'lib/graphql_schema/version'

Gem::Specification.new do |spec|
  spec.name          = "graphql_schema"
  spec.version       = GraphQLSchema::VERSION
  spec.authors       = ["Dylan Thacker-Smith"]
  spec.email         = ["gems@shopify.com"]

  spec.required_ruby_version = ">= 2.7"

  spec.summary       = "Classes for convenient use of GraphQL introspection result"
  spec.homepage      = "https://github.com/Shopify/graphql_schema"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata['allowed_push_host'] = "https://rubygems.org"

  spec.add_development_dependency "graphql", ">= 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
