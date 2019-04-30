# light-sidekiq
For any ruby application. 
Initiate listener: 
```
RedisHelper.initiate_redis
th1 = Thread.new { JobServer::Boot.boot }.run
th1.join
```

And add your jobs(your must have class method - perform):
```
JobServer.enqueue_job('AnyJob')
```