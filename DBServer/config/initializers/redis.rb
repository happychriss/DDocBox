$redis = Redis.new(:host => 'redis', :port => 6379)
$redis.set("upload_count","0")
$redis.set("backup_count","0")

