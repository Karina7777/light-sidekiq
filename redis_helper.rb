require 'securerandom'

module RedisHelper
  module_function

  def initiate_redis(namespce = :light_sidekiq)
    redis = Redis.new(port: 6379)
    @@redis = Redis::Namespace.new(namespce, :redis => redis)
  end


  def push_to_redis(class_name:, args:, status:, uid: nil)
    values   = redis.get(class_name)
    args     = args == [] ? nil : args
    uid      = uid.nil? ? SecureRandom.uuid : uid
    new_item = { args: args, status: status, uid: uid }

    push_value = if values.nil? 
      [new_item]
    else
      arr = JSON.parse(values)
      arr.push(new_item)
    end

    redis.set(class_name, push_value.to_json)
  end

  def del_from_redis(class_name:, uid:, status:)
    values           = JSON.parse(redis.get(class_name))
    index_for_remove = values.find_index{ |s| s['uid'] == uid && s['status'] == status }
    unless index_for_remove.nil?
      values.delete_at(index_for_remove)
      redis.set(class_name, values.to_json)
    end
  end

  # REDIS STRUCTURE -> { klass: 'ClassJob',  
  #                           values: [{ args: '', status: 'success', uid: '...' }, 
  #                                   { args: '', status: 'failed', uid: '...' } ... ] }
  def get_by_status(status)
    class_names = redis.keys('*')
    result = [ ]
    class_names.each do |class_name|
      values = JSON.parse(redis.get(class_name))
      bunch  = values.select {|v| v['status'] == status }

      unless bunch.empty?
        result << { klass: class_name, values: bunch }
      end
    end

    result 
  end

  def exist_in_redis?(class_name:, uid:, status:)
    values = JSON.parse(redis.get(class_name))
    values.select {|v| v['status'] == status && v['uid'] == uid }.any? 
  end

  def clear_key(key)
    redis.del(key)
  end

  private
  module_function

  def redis
    @mutex ||= Mutex.new
    @mutex.synchronize do
      @@redis
    end
  end

end