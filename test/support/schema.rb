require 'graphql'
require 'json'

module Support
  module Schema
    class Key < GraphQL::Schema::Enum
      description "Types of values that can be stored in a key"
      value("STRING")
      value("INTEGER")
      value("NOT_FOUND", deprecation_reason: "GraphQL null now used instead")
    end

    class Time < GraphQL::Schema::Scalar
      description "Time since epoch in seconds"
    end

    module Entry
      include GraphQL::Schema::Interface

      field :key, String, null: false
      field :ttl, Time, null: true
    end

    class StringEntry < GraphQL::Schema::Object
      implements Entry
      field :key, String, null: false
      field :value, String, null: false
      field :ttl, Time, null: true
    end

    class IntegerEntry < GraphQL::Schema::Object
      implements Entry
      field :key, String, null: false
      field :value, Int, null: false
      field :ttl, Time, null: true
    end

    class QueryRoot < GraphQL::Schema::Object
      field :get, String, null: true, deprecation_reason: "Ambiguous, use get_string instead" do
        description "Get a string value with the given key"
        argument :key, String, required: true
      end
      field :get_string, String do
        description "Get a string value with the given key"
        argument :key, String, required: true
      end
      field :get_integer, Int do
        description "Get a integer value with the given key"
        argument :key, String, required: true
      end
      field :get_entry, Entry, null: true do
        description "Get an entry of any type with the given key"
        argument :key, String, required: true
      end
      field :type, Key, null: true
      field :ttl, Time, null: true
      field :keys, [String], null: false do
        argument :first, String, required: true
        argument :after, String, required: false
      end
      field :entries, [Entry], null: false do
        argument :first, String, required: true
        argument :after, String, required: false
      end
    end

    class SetIntegerInput < GraphQL::Schema::InputObject
      argument :key, String, required: true
      argument :value, Int, required: true
      argument :ttl, Time, required: false
      argument :negate, Boolean, default_value: false, required: false
    end

    class MutationRoot < GraphQL::Schema::Object
      field :set, String, null: true, deprecation_reason: "Ambiguous, use set_string instead" do
        argument :key, String, required: true
      end
      field :set_string, Boolean, null: false do
        argument :key, String, required: true
        argument :value, String, required: true
      end
      field :set_string_with_default, Boolean, null: false do
        argument :key, String, required: true
        argument :value, String, required: false, default_value: "I am default"
      end
      field :set_integer, Boolean, null: false do
        argument :input, SetIntegerInput, required: true
      end
    end

    class DirectiveExample < GraphQL::Schema::Directive
      description "A nice runtime customization"
      locations FIELD
      argument :input, SetIntegerInput, required: true
      argument :enabled, Boolean, required: false
    end

    class ExampleSchema < GraphQL::Schema
      query QueryRoot
      mutation MutationRoot
      directive DirectiveExample
      orphan_types [StringEntry, IntegerEntry]
    end

    class NoMutationSchema < GraphQL::Schema
      query QueryRoot
      orphan_types [StringEntry, IntegerEntry]
    end
  end
end
