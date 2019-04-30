require './boot.rb'
require './redis_helper.rb'

module JobServer
  module_function

  def get_all_jobs
    RedisHelper.get_by_status('queue') + 
    RedisHelper.get_by_status('failed')
  end

  def enqueue_job(job_class, *args)
    RedisHelper.push_to_redis(class_name: job_class.new.class.name, args: args, status: 'queue')
  end

end
