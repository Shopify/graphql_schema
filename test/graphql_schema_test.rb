require 'test_helper'

class GraphQLSchemaTest < Minitest::Test
  def setup
    @schema = GraphQLSchema.new(Support::Schema::ExampleSchema.as_json)
  end

  def test_that_it_has_a_version_number
    refute_nil ::GraphQLSchema::VERSION
  end

  def test_application_types
    expect = %w(QueryRoot MutationRoot Entry IntegerEntry StringEntry Time Key SetIntegerInput).sort
    assert_equal expect, @schema.types.reject(&:builtin?).map(&:name)
  end

  def test_roots
    assert_equal 'QueryRoot', @schema.query_root_name
    assert_equal 'MutationRoot', @schema.mutation_root_name
    assert_equal ['MutationRoot', 'QueryRoot'], @schema.types.select { |type| @schema.root_name?(type.name) }.map(&:name)
  end

  def test_no_mutation_root
    schema = GraphQLSchema.new(Support::Schema::NoMutationSchema.as_json)
    assert_nil schema.mutation_root_name
  end

  def test_camelize_name
    assert_equal 'queryRoot', query_root.camelize_name
    assert_equal 'getString', get_string_field.camelize_name
    assert_equal 'notFound', not_found_value.camelize_name
  end

  def test_classify_name
    assert_equal 'QueryRoot', query_root.classify_name
    assert_equal 'GetString', get_string_field.classify_name
    assert_equal 'NotFound', not_found_value.classify_name
  end

  def test_upcase_name
    assert_equal 'QUERY_ROOT', query_root.upcase_name
    assert_equal 'GET_STRING', get_string_field.upcase_name
    assert_equal 'NOT_FOUND', not_found_value.upcase_name
  end

  def test_nil_fields
    assert_nil type('Key').fields
  end

  def test_deprecated_fields
    deprecated = query_root.fields(include_deprecated: true) - query_root.fields
    assert_equal %w(get), deprecated.map(&:name)
    assert_equal "Ambiguous, use get_string instead", deprecated.first.deprecation_reason
  end

  def test_deprecated_enum_values
    deprecated = type('Key').enum_values(include_deprecated: true) - type('Key').enum_values
    assert_equal %w(NOT_FOUND), deprecated.map(&:name)
    assert_equal "GraphQL null now used instead", deprecated.first.deprecation_reason
  end

  def test_of_type
    assert_equal 'NON_NULL', keys_field.type.kind
    assert_equal 'LIST', keys_field.type.of_type.kind
    assert_equal 'NON_NULL', keys_field.type.of_type.of_type.kind
    assert_equal 'String', keys_field.type.of_type.of_type.of_type.name
  end

  def test_non_null?
    assert_equal true, keys_field.type.non_null?
    assert_equal false, keys_field.type.unwrap.non_null?
  end

  def test_list?
    assert_equal true, keys_field.type.unwrap_non_null.list?
    assert_equal false, keys_field.type.unwrap_non_null.unwrap_list.list?
  end

  def test_unwrap
    assert_equal 'String', keys_field.type.unwrap.name
  end

  def test_unwrap_non_null
    assert_equal 'LIST', keys_field.type.unwrap_non_null.kind
    assert_equal 'String', keys_field.type.unwrap_non_null.unwrap.name
  end

  def test_unwrap_list
    assert_equal 'NON_NULL', keys_field.type.unwrap_list.kind
    assert_equal 'String', keys_field.type.unwrap_list.unwrap.name
  end

  def test_input_fields
    assert_equal %w(key value ttl negate), type('SetIntegerInput').input_fields.map(&:name)
  end

  def test_required_input_fields
    assert_equal %w(key value), type('SetIntegerInput').required_input_fields.map(&:name)
  end

  def test_optional_input_fields
    assert_equal %w(ttl negate), type('SetIntegerInput').optional_input_fields.map(&:name)
  end

  def test_default_value_input_fields
    assert_equal "false", input_field('SetIntegerInput', 'negate').default_value
    assert_nil input_field('SetIntegerInput', 'ttl').default_value
  end

  def test_args
    assert_equal %w(first after), field('QueryRoot', 'keys').args.map(&:name)
  end

  def test_required_args
    assert_equal %w(first), field('QueryRoot', 'keys').required_args.map(&:name)
  end

  def test_optional_args
    assert_equal %w(after), field('QueryRoot', 'keys').optional_args.map(&:name)
  end

  def test_default_args
    assert_equal "\"I am default\"", arg('MutationRoot', 'setStringWithDefault', 'value').default_value
    assert_nil arg('MutationRoot', 'setStringWithDefault', 'key').default_value
  end

  def test_possible_types
    assert_equal %w(StringEntry IntegerEntry).sort, type('Entry').possible_types.map(&:name)
  end

  def test_subfields
    assert_equal false, field('QueryRoot', 'keys').subfields?
    assert_equal true, field('QueryRoot', 'entries').subfields?
  end

  def test_implement?
    assert_equal true, type('StringEntry').implement?('Entry')
    assert_equal false, type('QueryRoot').implement?('Entry')
  end

  def test_enum?
    assert_equal true, field('QueryRoot', 'type').type.enum?
    assert_equal false, field('QueryRoot', 'keys').type.enum?
  end

  def test_fields_by_name
    assert_equal get_string_field, type('QueryRoot').fields_by_name['getString']
    assert_equal get_field, type('QueryRoot').fields_by_name['get']
    assert_nil type('QueryRoot').fields_by_name['doesNotExist']
  end

  def test_type_by_name
    assert_equal type('SetIntegerInput'), @schema.types_by_name['SetIntegerInput']
    assert_nil @schema.types_by_name['IDoNotExist']
  end

  def test_description
    assert_equal 'Time since epoch in seconds', type('Time').description
    assert_nil type('StringEntry').description
    assert_nil type('Key').enum_values.first.description
    assert_nil input_field('SetIntegerInput', 'negate').description
    assert_equal 'Get an entry of any type with the given key', field('QueryRoot', 'getEntry').description
  end

  def test_directives
    example_directive = directive("directiveExample")
    assert_equal %w(input enabled), example_directive.args.map(&:name)
    assert_equal %w(input), example_directive.required_args.map(&:name)
    assert_equal %w(enabled), example_directive.optional_args.map(&:name)
    assert_equal "A nice runtime customization", example_directive.description
    assert_equal ["FIELD"], example_directive.locations
    refute example_directive.builtin?
    assert directive("skip").builtin?
    assert directive("include").builtin?
    assert directive("deprecated").builtin?
    assert directive("oneOf").builtin?
    assert directive("specifiedBy").builtin?
    assert_equal 6, @schema.directives.length
  end

  def test_to_h
    assert_equal({
      'kind' => 'SCALAR',
      'name' => 'Time',
      'description' => 'Time since epoch in seconds',
      'fields' => nil,
      'inputFields' => nil,
      'interfaces' => nil,
      'enumValues' => nil,
      'possibleTypes' => nil
    }, type('Time').to_h)

    assert_equal({
      'name' => 'negate',
      'description' => nil,
      'type' => {'kind' => 'SCALAR', 'name' => 'Boolean', 'ofType' => nil },
      'defaultValue' => 'false',
      "isDeprecated" => false,
      "deprecationReason" => nil
    }, input_field('SetIntegerInput', 'negate').to_h)

    assert_equal({
      'name' => 'INTEGER',
      'description' => nil,
      'isDeprecated' => false,
      'deprecationReason' => nil
    }, type('Key').enum_values.first.to_h)
  end

  private

  def type(name)
    @schema.types.find { |type| type.name == name }
  end

  def field(type_name, field_name)
    type(type_name).fields(include_deprecated: true).find { |field| field.name == field_name }
  end

  def directive(directive_name)
    @schema.directives.find do |dir|
      dir.name == directive_name
    end
  end

  def input_field(type_name, field_name)
    type(type_name).input_fields().find { |field| field.name == field_name }
  end

  def arg(type_name, field_name, arg_name)
    field(type_name, field_name).args.find { |arg| arg.name == arg_name }
  end

  def enum_value(type_name, value_name)
    type(type_name).enum_values(include_deprecated: true).find { |value| value.name == value_name }
  end

  def query_root
    type('QueryRoot')
  end

  def get_field
    field('QueryRoot', 'get')
  end

  def get_string_field
    field('QueryRoot', 'getString')
  end

  def keys_field
    field('QueryRoot', 'keys')
  end

  def not_found_value
    enum_value('Key', 'NOT_FOUND')
  end
end
