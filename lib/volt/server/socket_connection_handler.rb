require 'json'
require File.join(File.dirname(__FILE__), '../../../app/volt/tasks/query_tasks')

module Volt
  class SocketConnectionHandler
    # Create one instance of the dispatcher

    # We track the connected user_id with the channel for use with permissions.
    # This may be changed as new listeners connect, which is fine.
    attr_accessor :user_id

    def self.dispatcher=(val)
      @@dispatcher = val
    end

    def self.dispatcher
      @@dispatcher
    end

    # Sends a message to all, optionally skipping a users channel
    def self.send_message_all(skip_channel = nil, *args)
      return unless defined?(@@channels)
      @@channels.each do |channel|
        next if skip_channel && channel == skip_channel
        channel.send_message(*args)
      end
    end

    def initialize(session, *args)
      @session = session

      @@channels ||= []
      @@channels << self
    end

    def process_message(message)
      # self.class.message_all(message)
      # Messages are json and wrapped in an array
      message = JSON.parse(message).first

      @@dispatcher.dispatch(self, message)
    end

    def send_message(*args)
      str = JSON.dump([*args])

      @session.send(str)
    end

    def closed
      unless @closed
        @closed = true
        # Remove ourself from the available channels
        @@channels.delete(self)

        begin
          @@dispatcher.close_channel(self)
        rescue DRb::DRbConnError => e
        # ignore drb read of @@dispatcher error if child has closed
        end
      else
        Volt.logger.error("Socket Error: Connection already closed\n#{inspect}")
      end
    end

    def inspect
      "<#{self.class}:#{object_id}>"
    end
  end
end
