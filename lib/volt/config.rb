# Config lets a user set global config options for Volt.
require 'configurations'
class Volt
  include Configurations

  def self.setup
    yield self.config
  end

  configuration_defaults do |c|
    c.deflate = nil
  end

  # Resets the configuration to the default (empty hash)
  def self.reset_config!
    self.configure do |c|
      c.from_h({})
    end
  end

  # Load in all .rb files in the config folder
  def self.run_files_in_config_folder
    Dir[Dir.pwd + '/config/*.rb'].each do |config_file|
      require(config_file)
    end
  end
end