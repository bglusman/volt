module Configurations
  # Module configurable provides the API of configurations
  #
  module Configurable

    # Class methods that will get installed in the host module
    #
    module ClassMethods
      # Make unset value return nil instead of erroring
      #
      def configuration_values_default_to_nil!
        configuration.defaults_to_nil = true
      end
    end
  end
  
  class Configuration < BasicObject

    # Method missing gives access for reading and writing to the underlying configuration hash via dot notation
    #
    def method_missing(method, *args, &block)
      property = method.to_s[0..-2].to_sym
      value = args.first

      if _respond_to_writer?(method)
        _assign!(property, value)
      elsif _respond_to_property?(method)
        @configuration[method]
      elsif _can_delegate_to_kernel?(method)
        ::Kernel.send(method, *args, &block)
      else
        defaults_to_nil ? nil : super
      end
    end

    attr_accessor :defaults_to_nil
  end
end
