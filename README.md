# GraphQL Schema

Classes to more conveniently access the GraphQL instrospection
result rather than using the parsed json directly as a hash.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql_schema'
```

And then execute:
```
bundle
```

Or install it yourself as:
```
gem install graphql_schema
```

## Usage

```ruby
require 'graphql_schema'
require 'json'

introspection_result = JSON.parse(File.read("schema.json"))
schema = GraphQLSchema.new(introspection_result)
schema.types.select(&:object_type?).each do |type|
  type.fields.each do |field|
    puts "#{field.name} -> #{field.type.name}"
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) for more information.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

