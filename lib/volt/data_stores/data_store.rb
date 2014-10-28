require 'volt/data_stores/mongo_driver'

class Volt
  class DataStore
    def self.fetch
      if Volt.configuration.db_driver == 'mongo'
        return MongoDriver.fetch
      else
        raise "#{database_name} is not a supported database"
      end
    end
  end
end