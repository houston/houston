module ProjectAdapter


  def adapters
    @adapters ||= {}
  end


  def has_adapter(*adapter_namespaces)
    adapter_namespaces.each do |adapter_namespace|
      adapter_module = Houston::Adapters[adapter_namespace]
      raise ArgumentError, "#{adapter_module} should respond to `adapters`" unless adapter_module.respond_to?(:adapters)
      raise ArgumentError, "#{adapter_module} should respond to `adapter`" unless adapter_module.respond_to?(:adapter)

      adapter = Adapter.new(self, adapter_module)
      adapters[adapter.name] = adapter

      adapter.define_methods!

      validate adapter.validation_method
    end
  end


  class Adapter

    def initialize(model, adapter_module)
      @model          = model
      @namespace      = adapter_module
      @name           = adapter_module.name
      @attribute_name = name.demodulize.underscore
    end

    attr_reader :model, :namespace, :name, :attribute_name

    def title
      name.demodulize.titleize
    end

    def validation_method
      :"#{attribute_name}_configuration_is_valid"
    end

    def define_methods!
      model.module_eval <<-RUBY
        def self.with_#{attribute_name}
          where arel_table[:#{attribute_name}_name].not_eq("None")
        end

        def has_#{attribute_name}?
          #{attribute_name}_name != "None"
        end

        def #{validation_method}
          #{attribute_name}_adapter.errors_with_parameters(self, *parameters_for_#{attribute_name}_adapter.values).each do |attribute, messages|
            errors.add(attribute, messages) if messages.any?
          end
        end

        def #{attribute_name}
          @#{attribute_name} ||= #{attribute_name}_adapter
              .build(self, *parameters_for_#{attribute_name}_adapter.values)
              .extend(FeatureSupport)
        end

        def parameters_for_#{attribute_name}_adapter
          #{attribute_name}_adapter.parameters.each_with_object({}) do |parameter, hash|
            hash[parameter] = extended_attributes[parameter.to_s]
          end
        end

        def #{attribute_name}_adapter
          #{namespace}.adapter(#{attribute_name}_name)
        end
      RUBY
    end

  end


end
