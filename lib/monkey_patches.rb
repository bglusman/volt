module Configurations
  # Module configurable provides the API of configurations
  #
  module Configurable
    # Installs #configure in base, and makes sure that it will instantiate configuration as a subclass of the host module
    #
    def install_configure_in(base)
      base.class_eval <<-EOF
        class << self
          # The central configure method
          # @params [Proc] block the block to configure host module with
          # @raise [ArgumentError] error when not given a block
          # @example Configure a configuration
          #   MyGem.configure do |c|
          #     c.foo = :bar
          #   end
          #
          def configure(&block)
            raise ArgumentError, 'can not configure without a block' unless block_given?
            @configuration = #{self}::Configuration.new(@configuration_defaults, @configurable, @configuration_values_default_to_nil, &block)
          end
        end
      EOF
    end

    # Class methods that will get installed in the host module
    #
    module ClassMethods
      # Make unset value return nil instead of erroring
      #
      def configuration_values_default_to_nil!
        @configuration_values_default_to_nil = true
      end
    end
  end

  class Configuration < BasicObject
    # Initialize a new configuration
    # @param [Proc] configuration_defaults A proc yielding to a default configuration
    # @param [Hash] configurable a hash of configurable properties and their asserted types if given
    # @param [Proc] block a block to configure this configuration with
    # @return [HostModule::Configuration] a configuration
    #
    def initialize(configuration_defaults, configurable, defaults_to_nil, &block)
      @_writeable = true
      @configurable = configurable
      @configuration = _configuration_hash
      @defaults_to_nil = defaults_to_nil

      _evaluate_configurable!

      self.instance_eval(&configuration_defaults) if configuration_defaults

      if block
        self.instance_eval(&block)
        self._writeable = false
      end
    end

    attr_reader :defaults_to_nil


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

    private
    # @return [Hash] A configuration hash instantiating subhashes if the key is configurable
    #
    def _configuration_hash
      ::Hash.new do |h, k|
        h[k] = Configuration.new(nil, @configurable, @defaults_to_nil) if _configurable?(k)
      end
    end

    # Evaluates configurable properties and passes eventual hashes down to subconfigurations
    #
    def _evaluate_configurable!
      return if _arbitrarily_configurable?

      @configurable.each do |k, assertion|
        if k.is_a?(::Hash)
          k.each do |property, nested|
            @configuration[property] = Configuration.new(nil, _configurable_hash(property, nested, assertion), @defaults_to_nil)
          end
        end
      end
    end

  end
end
