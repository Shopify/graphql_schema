require 'graphql'
require 'json'

module Support
  module Schema
    KeyType = GraphQL::EnumType.define do
      name "KeyType"
      description "Types of values that can be stored in a key"
      value("STRING")
      value("INTEGER")
      value("NOT_FOUND", deprecation_reason: "GraphQL null now used instead")
    end

    TimeType = GraphQL::ScalarType.define do
      name "Time"
      description "Time since epoch in seconds"
    end

    EntryType = GraphQL::InterfaceType.define do
      name "Entry"
      field :key, !types.String
      field :ttl, TimeType
    end

    StringEntryType = GraphQL::ObjectType.define do
      name "StringEntry"
      interfaces [EntryType]
      field :key, !types.String
      field :value, !types.String
      field :ttl, TimeType
    end

    IntegerEntryType = GraphQL::ObjectType.define do
      name "IntegerEntry"
      interfaces [EntryType]
      field :key, !types.String
      field :value, !types.Int
      field :ttl, TimeType
    end

    QueryType = GraphQL::ObjectType.define do
      name "QueryRoot"

      field :get, types.String do
        description "Get a string value with the given key"
        deprecation_reason "Ambiguous, use get_string instead"
        argument :key, !types.String
      end
      field :get_string, types.String do
        description "Get a string value with the given key"
        argument :key, !types.String
      end
      field :get_integer, types.Int do
        description "Get a integer value with the given key"
        argument :key, !types.String
      end
      field :get_entry, EntryType do
        description "Get an entry of any type with the given key"
        argument :key, !types.String
      end
      field :type, KeyType
      field :ttl, TimeType
      field :keys, !types[!types.String] do
        argument :first, !types.String
        argument :after, types.String
      end
      field :entries, !types[!EntryType] do
        argument :first, !types.String
        argument :after, types.String
      end
    end

    SetIntegerInput = GraphQL::InputObjectType.define do
      name "SetIntegerInput"
      argument :key, !types.String
      argument :value, !types.Int
      argument :ttl, TimeType
      argument :negate, types.Boolean, default_value: false
    end

    MutationType = GraphQL::ObjectType.define do
      name "Mutation"

      field :set, types.String do
        deprecation_reason "Ambiguous, use set_string instead"
        argument :key, !types.String
      end
      field :set_string, !types.Boolean do
        argument :key, !types.String
        argument :value, !types.String
      end
      field :set_string_with_default, !types.Boolean do
        argument :key, !types.String
        argument :value, types.String, default_value: "I am default"
      end
      field :set_integer, !types.Boolean do
        argument :input, !SetIntegerInput
      end
    end

    class DirectiveExample < GraphQL::Schema::Directive
      description "A nice runtime customization"
      locations FIELD
      argument :input, !SetIntegerInput, required: true
      argument :enabled, Boolean, required: false
    end

    ExampleSchema = GraphQL::Schema.define do
      query QueryType
      mutation MutationType
      directive(DirectiveExample)
      orphan_types [StringEntryType, IntegerEntryType]
      resolve_type ->(obj, ctx) {}
    end

    NoMutationSchema = GraphQL::Schema.define do
      query QueryType
      orphan_types [StringEntryType, IntegerEntryType]
      resolve_type ->(obj, ctx) {}
    end

    def self.introspection_result(schema = ExampleSchema)
      GraphQL::Query.new(schema, GraphQL::Introspection::INTROSPECTION_QUERY).result
    end
  end
end
