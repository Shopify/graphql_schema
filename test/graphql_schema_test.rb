require 'test_helper'

class GraphQLSchemaTest < Minitest::Test
  def setup
    @schema = GraphQLSchema.new(Support::Schema.introspection_result)
  end

  def test_that_it_has_a_version_number
    refute_nil ::GraphQLSchema::VERSION
  end

  def test_application_types
    expect = %w(QueryRoot Mutation Entry IntegerEntry StringEntry Time KeyType SetIntegerInput).sort
    assert_equal expect, @schema.types.reject(&:builtin?).map(&:name)
  end

  def test_roots
    assert_equal 'QueryRoot', @schema.query_root_name
    assert_equal 'Mutation', @schema.mutation_root_name
    assert_equal ['Mutation', 'QueryRoot'], @schema.types.select { |type| @schema.root_name?(type.name) }.map(&:name)
  end

  def test_no_mutation_root
    schema = GraphQLSchema.new(Support::Schema.introspection_result(Support::Schema::NoMutationSchema))
    assert_equal nil, schema.mutation_root_name
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

  def test_deprecated_fields
    deprecated = query_root.fields(include_deprecated: true) - query_root.fields
    assert_equal %w(get), deprecated.map(&:name)
    assert_equal "Ambiguous, use get_string instead", deprecated.first.deprecation_reason
  end

  def test_deprecated_enum_values
    deprecated = type('KeyType').enum_values(include_deprecated: true) - type('KeyType').enum_values
    assert_equal %w(NOT_FOUND), deprecated.map(&:name)
    assert_equal "GraphQL null now used instead", deprecated.first.deprecation_reason
  end

  def test_of_type
    assert_equal 'NON_NULL', keys_field.type.kind
    assert_equal 'LIST', keys_field.type.of_type.kind
    assert_equal 'NON_NULL', keys_field.type.of_type.of_type.kind
    assert_equal 'String', keys_field.type.of_type.of_type.of_type.name
  end

  def test_unwrap
    assert_equal 'String', keys_field.type.unwrap.name
  end

  def test_unwrap_non_null
    assert_equal 'LIST', keys_field.type.unwrap_non_null.kind
    assert_equal 'String', keys_field.type.unwrap_non_null.unwrap.name
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
    assert_equal nil, input_field('SetIntegerInput', 'ttl').default_value
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
    assert_equal "\"I am default\"", arg('Mutation', 'set_string_with_default', 'value').default_value
    assert_equal nil, arg('Mutation', 'set_string_with_default', 'key').default_value
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

  private

  def type(name)
    @schema.types.find { |type| type.name == name }
  end

  def field(type_name, field_name)
    type(type_name).fields(include_deprecated: true).find { |field| field.name == field_name }
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

  def get_string_field
    field('QueryRoot', 'get_string')
  end

  def keys_field
    field('QueryRoot', 'keys')
  end

  def not_found_value
    enum_value('KeyType', 'NOT_FOUND')
  end
end
