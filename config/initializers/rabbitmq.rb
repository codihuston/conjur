# frozen_string_literal: true
require "bunny"
require "singleton"

class RabbitMQClient
  include Singleton

  def initialize
    connect
  end

  def connect
    # TODO: verify these work without hardcoding 
    @active_connection = Bunny.new({
      host: ENV["RABBITMQ_HOST"],
      vhost: ENV["RABBITMQ_VHOST"],
      user: ENV["RABBITMQ_USER"],
      password: ENV["RABBITMQ_PASS"],
      automatically_recover: true
    })

    @active_connection.start
    @active_channel = @active_connection.create_channel
    # queue = channel.queue('hello')
    @active_connection
  end

  def connection
    return @active_connection if connected?

    connect
  
    @active_connection
  end

  def channel
    return @active_channel if connected? && @active_channel&.open?

    connect

    @active_channel
  end

  def connected?
    @active_connection&.connected?
  end
end

class Publisher
  DEFAULT_OPTIONS = { durable: true, auto_delete: false }.freeze

  def self.publish(queue_name:, payload:)
    channel = RabbitMQClient.instance.channel
    queue = channel.queue(queue_name, DEFAULT_OPTIONS)
    queue.publish(payload, routing_key: queue.name)
  end
end

# docker exec -it dev_conjur_1 bash
# irb
# require "./config/initializers/rabbitmq"
# Publisher.publish(queue_name: "greetings", payload: "qweqw")


# Publisher.publish(queue_name: "greetings", payload: { hello: :world })
