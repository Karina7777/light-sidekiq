require './job_server.rb'

RSpec.describe JobServer, type: :job do
  RedisHelper.initiate_redis(:light_sidekiq_test)

  before :each do
    RedisHelper.clear_key('TimerJob')
  end

  it 'success enqueue' do
    JobServer.enqueue_job(TimerJob)
    jobs = JobServer.get_all_jobs

    jobs.each do |job|
      expect('TimerJob').to eq(job[:klass])

      values = job[:values]
      values.each do |value|
        expect(value['status']).to eq('queue') 
      end
    end
  end

  it 'failed enqueue' do
    JobServer.enqueue_job(TimerJob, 'not needed argument')
    JobServer::Boot.perform_by_status('queue')
    
    sleep 1
    last_values = JobServer.get_all_jobs.last[:values].last
    expect(last_values['status']).to eq('failed')
  end

end
