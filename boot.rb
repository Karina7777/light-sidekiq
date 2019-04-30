require 'redis'
require 'redis-namespace'
require 'pry'
require './redis_helper.rb'
require 'json'
Dir["./job_examples/*.rb"].each {|file| require file }

module JobServer 
  class Boot
    class << self
      include RedisHelper

      SLEEP_QUEUE  = 5
      SLEEP_FAILED = 5

      def boot
        catch_term
        initiate_infinity
      end

      def perform_by_status(status)
        result = get_by_status(status)

        unless result.empty?
          result.each do |data|
            klass_str = data[:klass]
            klass     = Object.const_get(klass_str)
            values    = data[:values]

            values.each do |value|
              Process.fork do
                arg = value['args']
                uid = value['uid']
                begin
                  arg.nil? ? klass.perform : klass.perform(arg)
                  push_to_redis(class_name: klass, args: arg, uid: uid, status: 'success')
                  del_from_redis(class_name: klass, uid: uid, status: 'queue')
                  del_from_redis(class_name: klass, uid: uid, status: 'failed')
                  puts '(ᵔᴥᵔ)'
                rescue StandardError => e
                  puts e
                  puts '(╯°□°）╯'
                  unless exist_in_redis?(class_name: klass, uid: uid, status: 'failed')
                    push_to_redis(class_name: klass, args: arg, uid: uid, status: 'failed')
                  end
                end
              end
            end
          end
        end
      end

      private

      def initiate_infinity
        @main_thread = Thread.new do
          while true
            puts "Zzzzzzz...."
            sleep SLEEP_QUEUE
            perform_by_status('queue')
            sleep SLEEP_FAILED 
            perform_by_status('failed')
          end
        end
        @main_thread.run
        @main_thread.join
      end

      def catch_term
        Signal.trap('INT') do 
          puts 'Goodbuy'
          Thread.kill(@main_thread)
        end
      end

    end
  end
end
