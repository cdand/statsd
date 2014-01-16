require 'benchmark'
require 'eventmachine'
require 'json'
module Statsd
  class Zabbix < EM::Connection
    attr_accessor :counters, :timers, :gauges, :flush_interval
    
    def initialize(*args)
      puts args
      super
      # stuff here...
    end
    
    def post_init
      # puts counters.size
      # send_data 'Hello'
      # puts 'hello'
      # close_connection_after_writing
    end

    def receive_data(data)
      p data      
    end

    # def unbind
    #   p ' connection totally closed'
    #   EventMachine::stop_event_loop
    # end
          
    def flush_stats
      print "#{Time.now} Flushing #{counters.count} counters to Zabbix."
      stat_hash = { "request" => "sender data"}
      stat_array = []

      time = ::Benchmark.realtime do
        ts = Time.now.to_i
        num_stats = 0

        # store counters
        counters.each_pair do |hostkey,value|
          host, key = hostkey.split("-")
          message = { "host" => "#{host}", "key" => "#{key}", "value" => "#{value}" }
          stat_array << message
          counters[hostkey] = 0

          num_stats += 1
        end
      end

      unless stat_array.empty?
        stat_hash["data"] = stat_array
        data = JSON.generate stat_hash
        data_length = data.bytesize
        data_header = "ZBXD\1".encode("ascii") + \
                      [data_length].pack("i") + \
                      "\x00\x00\x00\x00"
        data_to_send = data_header + data
        send_data data_to_send
      end

      puts " Complete. (#{time.round(3)}s)"
      close_connection_after_writing
    end
  end
end
