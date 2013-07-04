def = require("promised-io/promise").Deferred

define ['cs!lib/redis_client'], (RedisClient) ->
  ->
    reconcileFunction = "
      local keys_to_remove = redis.call('KEYS', 'user:*')
      for i=1, #keys_to_remove do
        redis.call('DEL', keys_to_remove[i])
      end

      local processes = redis.call('KEYS', 'process:*')
      for i=1, #processes do
        local users_in_process = redis.call('LRANGE', processes[i], 0, -1)
        for j=1, #users_in_process do
          redis.call('INCR', 'user:' .. users_in_process[j])
        end
      end
    "

    dfd = new def()
    RedisClient.script 'load', reconcileFunction, (err, res) ->
      dfd.resolve(res)
    dfd.promise
