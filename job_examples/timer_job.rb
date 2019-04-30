require './job_server.rb'

class TimerJob

  def self.perform
    3.times { |n| puts n }
  end

end