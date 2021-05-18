require "graphql_schema/version"
require 'set'

class GraphQLSchema
  def initialize(instrospection_result)
    @hash = instrospection_result.fetch('data').fetch('__schema')
  end

  def root_name?(type_name)
    type_name == query_root_name || type_name == mutation_root_name
  end

  def query_root_name
    @query_root_name ||= @hash.fetch('queryType').fetch('name')
  end

  def mutation_root_name
    if mutation_type = @hash.fetch('mutationType')
      mutation_type.fetch('name')
    end
  end

  def directives
    @directives ||= @hash.fetch('directives').map do |directive|
      Directive.new(directive)
    end.sort_by(&:name)
  end

  def types
    @types ||= @hash.fetch('types').map{ |type_hash| TypeDefinition.new(type_hash) }.sort_by(&:name)
  end

  def types_by_name
    @types_by_name ||= types.map { |type| [type.name, type] }.to_h
  end

  module WithArgs
    def args
      @args ||= @hash.fetch('args').map{ |arg_hash| InputValue.new(arg_hash) }
    end
  end

  module NamedHash
    def name
      @hash.fetch('name')
    end

    def camelize_name
      @camelize_name ||= begin
        words = split_name.map(&:capitalize)
        words[0] = words[0].downcase
        words.join
      end
    end

    def classify_name
      @classify_name ||= split_name.map(&:capitalize).join
    end

    def upcase_name
      @upcase_name ||= split_name.join("_").upcase
    end

    def description
      @hash.fetch('description')
    end

    def to_h
      @hash
    end

    private

    def split_name
      @split_name ||= name.gsub(/([a-z])([A-Z0-9])/) { "#{$1}_#{$2}" }.split("_")
    end
  end

  module Deprecatable
    def deprecated?
      @hash.fetch('isDeprecated')
    end

    def deprecation_reason
      @hash.fetch('deprecationReason')
    end
  end

  class InputValue
    include NamedHash

    def initialize(arg_hash)
      @hash = arg_hash
    end

    def type
      @type ||= TypeDeclaration.new(@hash.fetch('type'))
    end

    def default_value
      @default_value ||= @hash.fetch('defaultValue')
    end
  end

  class Field
    include NamedHash
    include Deprecatable
    include WithArgs

    def initialize(field_hash)
      @hash = field_hash
    end

    def required_args
      @required_args ||= args.select{ |arg| arg.type.non_null? }
    end

    def optional_args
      @optional_args ||= args.reject{ |arg| arg.type.non_null? }
    end

    def type
      @type ||= TypeDeclaration.new(@hash.fetch('type'))
    end

    def subfields?
      type.subfields?
    end
  end

  class EnumValue
    include NamedHash
    include Deprecatable

    def initialize(enum_value_hash)
      @hash = enum_value_hash
    end
  end

  class Type
    include NamedHash

    BUILTIN = %w(Int Float String Boolean ID).to_set

    def initialize(type_hash)
      @hash = type_hash
    end

    def kind
      @hash.fetch('kind')
    end

    def scalar?
      kind == 'SCALAR'
    end

    def object?
      kind == 'OBJECT'
    end

    def input_object?
      kind == 'INPUT_OBJECT'
    end

    def interface?
      kind == 'INTERFACE'
    end

    def enum?
      kind == 'ENUM'
    end

    def union?
      kind == 'UNION'
    end

    def list?
      kind == 'LIST'
    end

    def builtin?
      name.start_with?("__") || BUILTIN.include?(name)
    end
  end

  class TypeDeclaration < Type
    def of_type
      @of_type ||= TypeDeclaration.new(@hash.fetch('ofType'))
    end

    def list?
      kind == 'LIST'
    end

    def non_null?
      kind == 'NON_NULL'
    end

    def unwrap
      case kind
      when 'NON_NULL', 'LIST'
        of_type.unwrap
      else
        self
      end
    end

    def unwrap_list
      list? ? of_type.unwrap_list : self
    end

    def unwrap_non_null
      non_null? ? of_type.unwrap_non_null : self
    end

    def subfields?
      case unwrap.kind
      when 'OBJECT', 'INTERFACE', 'UNION'
        true
      else
        false
      end
    end
  end

  class Directive
    include NamedHash
    include WithArgs

    BUILTIN = %w(skip include deprecated).to_set

    def initialize(directive)
      @hash = directive
    end

    def locations
      @hash.fetch('locations')
    end

    def builtin?
      BUILTIN.include?(name)
    end
  end

  class TypeDefinition < Type
    def fields(include_deprecated: false)
      return unless @hash.fetch('fields')
      @fields ||= @hash.fetch('fields').map{ |field_hash| Field.new(field_hash) }
      include_deprecated ? @fields : @fields.reject(&:deprecated?)
    end

    def fields_by_name
      @fields_by_name ||= fields(include_deprecated: true).map{ |field| [field.name, field]}.to_h
    end

    def input_fields
      @input_fields ||= @hash.fetch('inputFields').map{ |field_hash| InputValue.new(field_hash) }
    end

    def required_input_fields
      @required_fields ||= input_fields.select{ |field| field.type.non_null? }
    end

    def optional_input_fields
      @optional_fields ||= input_fields.reject{ |field| field.type.non_null? }
    end

    def interfaces
      @interfaces ||= @hash.fetch('interfaces').map{ |type_hash| TypeDeclaration.new(type_hash) }.sort_by(&:name)
    end

    def implement?(interface_name)
      interfaces.map(&:name).include?(interface_name)
    end

    def possible_types
      @possible_types ||= @hash.fetch('possibleTypes').map{ |type_hash| TypeDeclaration.new(type_hash) }.sort_by(&:name)
    end

    def enum_values(include_deprecated: false)
      @enum_values ||= @hash.fetch('enumValues').map{ |value_hash| EnumValue.new(value_hash) }.sort_by(&:name)
      include_deprecated ? @enum_values : @enum_values.reject(&:deprecated?)
    end
  end
end
