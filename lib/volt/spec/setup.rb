require 'volt/volt/core' if RUBY_PLATFORM != 'opal'

module Volt
  class << self
    def spec_setup(app_path = '.')
      require 'volt'

      ENV['SERVER'] = 'true'
      ENV['VOLT_ENV'] = 'test'

      require 'volt/boot'

      # Require in app
      volt_app = Volt.boot(app_path)

      unless RUBY_PLATFORM == 'opal'
        begin
          require 'volt/spec/capybara'

          setup_capybara(app_path, volt_app)
        rescue LoadError => e
          Volt.logger.warn("unable to load capybara, if you wish to use it for tests, be sure it is in the app's Gemfile")
          Volt.logger.error(e)
        end
      end

      unless ENV['BROWSER']
        # Not running integration tests with ENV['BROWSER']
        RSpec.configuration.filter_run_excluding type: :feature
      end



      cleanup_db = -> do
        Volt::DataStore.fetch.drop_database

        # Clear cached for a reset
        $page.instance_variable_set('@store', nil)
        QueryTasks.reset!
      end

      if RUBY_PLATFORM != 'opal'
        # Call once during setup to clear if we killed the last run
        cleanup_db.call
      end

      # Setup the spec collection accessors
      # RSpec.shared_context "volt collections", {} do
      RSpec.shared_examples_for 'volt collections', {} do
        # Page conflicts with capybara's page method, so we call it the_page for now.
        # TODO: we need a better solution for page

        let(:the_page) { Model.new }
        let(:store) do
          @__store_accessed = true
          $page ||= Page.new
          $page.store
        end


        if RUBY_PLATFORM != 'opal'
          after do
            if @__store_accessed
              # Clear the database after each spec where we use store
              cleanup_db.call
            end
          end

          # Assume store is accessed in capyabara specs
          before(:context, {type: :feature}) do
            @__store_accessed = true
          end

          # Cleanup after integration tests also.
          before(:example, {type: :feature}) do
            @__store_accessed = true
          end
        end
      end
    end
  end
end
