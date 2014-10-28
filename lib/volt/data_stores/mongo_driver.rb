require 'mongo'

class Volt
  class DataStore
    class MongoDriver
      def self.fetch
        @@mongo_db ||= Mongo::MongoClient.new(Volt.configuration.db_host, Volt.configuration.db_path)
        @@db ||= @@mongo_db.db(Volt.configuration.db_name)

        return @@db
      end
    end
  end
end